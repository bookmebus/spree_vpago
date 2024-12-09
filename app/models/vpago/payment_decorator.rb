module Vpago
  module PaymentDecorator
    def self.prepended(base)
      base.has_many :payouts, class_name: 'Spree::Payout', inverse_of: :payment
      base.after_create -> { Vpago::PayoutsGenerator.new(self).call }, if: :should_generate_payouts?
      base.after_update :capture_pre_auth, if: :state_changed_to_complete?
      base.after_update :cancel_pre_auth, if: :state_changed_to_failed?
      base.scope :processing, -> { where(state: 'processing') }
    end

    def state_changed_to_complete?
      saved_change_to_state? && state == 'completed'
    end

    def state_changed_to_failed?
      saved_change_to_state? && state == 'failed'
    end

    def should_generate_payouts?
      support_payout? && payouts.empty?
    end

    def support_payout?
      payment_method.support_payout?
    end

    # On the first call, everything works. The order is transitioned to complete and one Spree::Payment,
    # which redirect the payment. But, after making the same call again,
    # for instance because the payment wasn't completed or failed,
    # another Spree::Payment is created but without a payment_url. So, if a consumer,
    # for whatever reason, failed to complete the first payment, it would not be possible try again.
    # This also meant that any consecutive Spree::Payment would not have a payment_url. The consumer is stuck

    def build_source
      return unless new_record?

      return unless source_attributes.present? && source.blank? && payment_method.try(:payment_source_class)

      self.source = payment_method.payment_source_class.new(source_attributes)
      source.payment_method_id = payment_method.id
      source.user_id = order.user_id if order

      # Spree will not process payments if order is completed.
      # We should call process! for completed orders to create a the gateway payment.
      process! if order.completed?
    end

    def request_update(ignore_on_failed: true)
      updater = payment_method.payment_request_updater.new(self, { ignore_on_failed: ignore_on_failed })
      updater.call
      updater
    end

    def authorized?
      if source.is_a? Spree::VpagoPaymentSource
        pending?
      else
        false
      end
    end

    def payment_url
      return unless payment_method.type_payway_v2?

      "#{ENV.fetch('DEFAULT_URL_HOST', nil)}/payway_v2_card_popups?payment_number=#{number}"
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

    def capture_pre_auth
      return if !enable_pre_auth? || pre_auth_completed?

      pre_auth_service.capture_pre_auth(self)
    end

    def cancel_pre_auth
      return if !enable_pre_auth? || pre_auth_cancelled?

      pre_auth_service.cancel_pre_auth(self)
    end

    def pre_auth_service
      payment_method.pre_auth_service
    end

    def enable_pre_auth?
      payment_method.enable_pre_auth?
    end
  end
end

Spree::Payment.prepend(Vpago::PaymentDecorator)