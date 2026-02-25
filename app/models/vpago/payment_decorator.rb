# Note for process! & capture! method:
#
# Original process! & capture! calls started_processing! to move state
# [:checkout, :pending, :completed, :processing] → :processing.
#
# When gateway call fails, handle_response calls send(:failure) which transitions
# the payment to :failed state. This happens BEFORE the GatewayError is raised,
# so when Sidekiq retries the job, the payment is already in :failed state.
#
# The :started_processing event doesn't allow transition from :failed → :processing,
# so we need to reset the state back to :checkout first via reset_for_retry!
#
# This allows process! or capture! to be retried by Sidekiq or by admin via /fire after connection errors
# or other transient gateway failures.
module Vpago
  module PaymentDecorator
    def self.prepended(base)
      base.has_many :payouts, class_name: 'Spree::Payout', inverse_of: :payment
      base.after_create -> { Vpago::PayoutsGenerator.new(self).call }, if: :should_generate_payouts?

      base.delegate :checkout_url,
                    :web_checkout_url,
                    :check_transaction_url,
                    :processing_url,
                    :success_url,
                    :process_payment_url,
                    :success_deeplink_url,
                    to: :url_constructor

      # Add state machine event for payment retry
      base.state_machine.event :reset_for_retry do
        transition from: %i[failed], to: :checkout
      end
    end

    # override
    def process!
      reset_for_retry! if failed?

      super
    end

    # override
    def capture!(amount = nil)
      reset_for_retry! if failed?

      super
    end

    # override:
    # to allow capture faraday connection error. gateway_error method already write rails log for this.
    def protect_from_connection_error
      yield
    rescue ActiveMerchant::ConnectionError => e
      failure!
      gateway_error(e)
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
      failure!
      gateway_error(ActiveMerchant::ConnectionError.new(e.message, e))
    end

    def user_informer
      @user_informer ||= ::Vpago::UserInformers::Firebase.new(order)
    end

    def url_constructor
      @url_constructor ||= Vpago::PaymentUrlConstructor.new(self)
    end

    def should_generate_payouts?
      payment_method.enable_payout? && payouts.empty?
    end

    # COMPLETED, CANCELLED
    def pre_auth_status
      pre_auth_response['transaction_status']
    end

    def pre_auth_completed?
      pre_auth_status == 'COMPLETED'
    end

    def pre_auth_cancelled?
      pre_auth_status == 'CANCELLED'
    end

    def true_money_payment?
      payment_method.type_true_money?
    end

    def vattanac_payment?
      payment_method.type_vattanac?
    end

    def vattanac_mini_app_payment?
      payment_method.type_vattanac_mini_app?
    end

    def check_payment?
      payment_method.type_check?
    end

    def can_redirect_to_app?
      payment_method.can_redirect_to_app?
    end
  end
end

Spree::Payment.prepend(Vpago::PaymentDecorator) unless Spree::Payment.included_modules.include?(Vpago::PaymentDecorator)
