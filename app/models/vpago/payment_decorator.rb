module Vpago
  module PaymentDecorator

    # On the first call, everything works. The order is transitioned to complete and one Spree::Payment, 
    # which redirect the payment. But, after making the same call again,
    # for instance because the payment wasn't completed or failed,
    # another Spree::Payment is created but without a payment_url. So, if a consumer,
    # for whatever reason, failed to complete the first payment, it would not be possible try again. 
    # This also meant that any consecutive Spree::Payment would not have a payment_url. The consumer is stuck

    def build_source
      return unless new_record?

      if source_attributes.present? && source.blank? && payment_method.try(:payment_source_class)
        self.source = payment_method.payment_source_class.new(source_attributes)
        source.payment_method_id = payment_method.id
        source.user_id = order.user_id if order

        # Spree will not process payments if order is completed.
        # We should call process! for completed orders to create a the gateway payment.
        process! if order.completed?
      end
    end

    def request_update
      updater = payment_method.payment_request_updater.new(self, { ignore_on_failed: true })
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
  end
end

Spree::Payment.prepend(Vpago::PaymentDecorator)