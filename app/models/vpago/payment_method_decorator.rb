module Vpago
  module PaymentMethodDecorator
    TYPE_PAYWAY = 'Spree::Gateway::Payway'.freeze
    TYPE_PAYWAY_V2 = 'Spree::Gateway::PaywayV2'.freeze
    TYPE_WINGSDK = 'Spree::Gateway::WingSdk'.freeze
    TYPE_ACLEDA = 'Spree::Gateway::Acleda'.freeze
    TYPE_ACLEDA_MOBILE = 'Spree::Gateway::AcledaMobile'.freeze

    def self.prepended(base)
      base.preference :icon_name, :string, default: 'cheque'
      base.belongs_to :vendor, class_name: 'Spree::Vendor', optional: true, inverse_of: :payment_methods

      def base.vpago_payments
        [
          Spree::PaymentMethod::TYPE_PAYWAY_V2,
          Spree::PaymentMethod::TYPE_PAYWAY,
          Spree::PaymentMethod::TYPE_WINGSDK,
          Spree::PaymentMethod::TYPE_ACLEDA,
          Spree::PaymentMethod::TYPE_ACLEDA_MOBILE
        ]
      end
    end

    def support_payout?
      return false unless type_payway_v2?
      return false unless default_payout_profile.present? && default_payout_profile.receivable?

      true
    end

    def support_pre_auth?
      type_payway_v2?
    end

    def default_payout_profile
      Spree::PayoutProfiles::PaywayV2.default
    end

    def vpago_payment?
      self.class.vpago_payments.include?(type)
    end

    def vapgo_checkout_service
      if type_payway?
        ::Vpago::Payway::Checkout
      elsif type_payway_v2?
        ::Vpago::PaywayV2::Checkout
      elsif type_wingsdk?
        ::Vpago::WingSdk::Checkout
      elsif type_acleda?
        ::Vpago::Acleda::Checkout
      end
    end

    def payment_request_updater
      if type_payway?
        ::Vpago::Payway::PaymentRequestUpdater
      elsif type_payway_v2?
        ::Vpago::PaywayV2::PaymentRequestUpdater
      elsif type_wingsdk?
        ::Vpago::WingSdk::PaymentRequestUpdater
      elsif type_acleda?
        ::Vpago::Acleda::PaymentRequestUpdater
      elsif type_acleda_mobile?
        ::Vpago::AcledaMobile::PaymentRequestUpdater
      end
    end

    def type_acleda_mobile?
      type == Spree::PaymentMethod::TYPE_ACLEDA_MOBILE
    end

    def type_acleda?
      type == Spree::PaymentMethod::TYPE_ACLEDA
    end

    def type_payway?
      type == Spree::PaymentMethod::TYPE_PAYWAY
    end

    def type_payway_v2?
      type == Spree::PaymentMethod::TYPE_PAYWAY_V2
    end

    def type_wingsdk?
      type == Spree::PaymentMethod::TYPE_WINGSDK
    end

    def pre_auth_service
      raise NotImplementedError, 'Pre-auth is not supported for this gateway' unless type_payway_v2?

      Vpago::PaywayV2::PreAuthHandler.new
    end
  end
end

Spree::PaymentMethod.prepend(Vpago::PaymentMethodDecorator) unless Spree::PaymentMethod.included_modules.include?(Vpago::PaymentMethodDecorator)
