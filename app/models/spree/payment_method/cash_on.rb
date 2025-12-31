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
  end
end
