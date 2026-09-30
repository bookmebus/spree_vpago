module Spree
  class PaymentMethod::CashOn < ::Spree::PaymentMethod
    def payment_source_class
      Spree::VpagoPaymentSource
    end

    def source_required?
      true
    end

    def auto_capture?
      true
    end

    # override: Spree::Payment#cancel! calls payment_method.cancel(response_code, payment).
    # Cash has no gateway to void against, so acknowledge success and let the payment
    # transition to `void`.
    def cancel(_response_code, _payment = nil)
      ActiveMerchant::Billing::Response.new(true, 'Cash On: Payment has been canceled.')
    end
  end
end
