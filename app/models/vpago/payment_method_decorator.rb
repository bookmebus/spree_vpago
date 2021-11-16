module Vpago
  module PaymentMethodDecorator
    TYPE_PAYWAY = 'Spree::Gateway::Payway'
    TYPE_WINGSDK = 'Spree::Gateway::WingSdk'
    TYPE_ACLEDA = 'Spree::Gateway::Acleda'

    def self.prepended(base)
      def base.vpago_payments
        [Spree::PaymentMethod::TYPE_PAYWAY, Spree::PaymentMethod::TYPE_WINGSDK, Spree::PaymentMethod::TYPE_ACLEDA]
      end
    end

    def vpago_payment?
      self.class.vpago_payments.include?(self.type)
    end

    def vapgo_checkout_service
      if type_payway?
        ::Vpago::Payway::Checkout
      elsif type_wingsdk?
        ::Vpago::WingSdk::Checkout
      elsif type_acleda?
        ::Vpago::Acleda::Checkout
      end
    end

    def type_acleda?
      type == Spree::PaymentMethod::TYPE_ACLEDA
    end

    def type_payway?
      type == Spree::PaymentMethod::TYPE_PAYWAY
    end

    def type_wingsdk?
      type == Spree::PaymentMethod::TYPE_WINGSDK
    end
  end
end

Spree::PaymentMethod.prepend(Vpago::PaymentMethodDecorator)
