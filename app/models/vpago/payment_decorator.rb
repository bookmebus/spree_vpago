module Vpago
  module PaymentDecorator
    def self.prepended(base)
      base.has_many :payouts, class_name: 'Spree::Payout', inverse_of: :payment
      base.after_create -> { Vpago::PayoutsGenerator.new(self).call }, if: :should_generate_payouts?

      base.delegate :checkout_url,
                    :processing_url,
                    :success_url,
                    :process_payment_url,
                    to: :url_constructor
    end

    def process!
      # give payment another chance to re-process, even if it failed.
      update!(state: :checkout) if processing? || send(:has_invalid_state?)

      super
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
  end
end

Spree::Payment.prepend(Vpago::PaymentDecorator) unless Spree::Payment.included_modules.include?(Vpago::PaymentDecorator)
