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
#
# Pre-auth capture! is the exception: it never leaves `pending` on failure, see #pre_auth_capture!.
module Vpago
  module PaymentDecorator
    def self.prepended(base)
      base.has_many :payouts, class_name: 'Spree::Payout', inverse_of: :payment
      base.after_create -> { Vpago::PayoutsGenerator.new(self).call }, if: :should_generate_payouts?

      base.delegate :checkout_url,
                    :web_checkout_url,
                    :processing_url,
                    :success_url,
                    :success_deeplink_url,
                    :check_transaction_url,
                    :process_payment_url,
                    to: :url_constructor

      # State machine event for payment retry / admin reprocess.
      # `failed` is auto-reset by process!/capture! below (Sidekiq retry);
      # void/invalid/processing are reset only by the admin reprocess action.
      base.state_machine.event :reset_for_retry do
        transition from: %i[failed void invalid processing], to: :checkout
      end
    end

    # Stores preloaded payout IDs in private_metadata to avoid N+1 queries
    # when checking whether payouts exist for this payment.
    def preload_payout_ids=(ids)
      self.private_metadata ||= {}
      self.private_metadata['preload_payout_ids'] = ids
    end

    def preload_payout_ids
      self.private_metadata&.fetch('preload_payout_ids', []) || []
    end

    # override
    def process!
      reset_for_retry! if failed?

      super
    end

    # override
    def capture!(amount = nil)
      return pre_auth_capture!(amount) if payment_method&.enable_pre_auth?

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

    # Authorized (ABA holds the money) but not captured yet: the order may already be complete,
    # yet nothing has been charged.
    def awaiting_pre_auth_capture?
      payment_method.enable_pre_auth? && (pending? || processing?)
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

    def acleda_mini_app_payment?
      payment_method.type_acleda_mini_app?
    end

    def wing_mini_app_payment?
      payment_method.type_wing_mini_app?
    end

    def check_payment?
      payment_method.type_check?
    end

    def can_redirect_to_app?
      payment_method.can_redirect_to_app?
    end

    private

    # Spree's capture! moves the payment to processing and, when the gateway fails, to failed.
    # For a pre-auth payment that is wrong: ABA still holds the money, and `failed` hides the
    # capture/void actions (VpagoPaymentSource requires `pending`), so PaymentCapturerJob's
    # Sidekiq retries found nothing to do and the capture was attempted only once.
    #
    # Here only a confirmed capture changes the state (pending -> completed). A failed attempt
    # writes nothing, so the payment stays retryable and a slow failing call can't overwrite a
    # concurrent success. The capture event is also written only when money actually moved
    # (Spree writes it before knowing the result).
    def pre_auth_capture!(amount)
      return true if completed?

      # A `failed` pre-auth payment was left by the old flow; its hold may or may not still be
      # active, so it must be checked with ABA and repaired before capturing again.
      gateway_error("Cannot capture pre-auth payment #{number} in state #{state}") unless pending? || processing?

      amount ||= money.amount_in_cents
      response = begin
        payment_method.capture(amount, response_code, gateway_options)
      rescue ActiveMerchant::ConnectionError, Faraday::Error => e
        # Spree logs nothing for a connection error; record it so the payment's log shows every attempt.
        record_response(ActiveMerchant::Billing::Response.new(false, "Payway Gateway: #{e.class}: #{e.message}", {}))
        gateway_error(ActiveMerchant::ConnectionError.new(e.message, e))
      end

      record_response(response)
      gateway_error(response) unless response.success?

      capture_events.create!(amount: ::Money.new(amount, currency).to_f)
      split_uncaptured_amount
      self.response_code = response.authorization if response.authorization.present?
      complete!
    end
  end
end

Spree::Payment.prepend(Vpago::PaymentDecorator) unless Spree::Payment.include?(Vpago::PaymentDecorator)
