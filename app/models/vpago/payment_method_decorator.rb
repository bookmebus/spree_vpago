module Vpago
  module PaymentMethodDecorator
    TYPE_PAYWAY = 'Spree::Gateway::Payway'.freeze
    TYPE_PAYWAY_V2 = 'Spree::Gateway::PaywayV2'.freeze
    TYPE_WINGSDK = 'Spree::Gateway::WingSdk'.freeze
    TYPE_ACLEDA = 'Spree::Gateway::Acleda'.freeze
    TYPE_ACLEDA_MOBILE = 'Spree::Gateway::AcledaMobile'.freeze
    TYPE_TRUE_MONEY = 'Spree::Gateway::TrueMoney'.freeze
    TYPE_VATTANAC = 'Spree::Gateway::Vattanac'.freeze
    TYPE_VATTANAC_MINI_APP = 'Spree::Gateway::VattanacMiniApp'.freeze

    def self.prepended(base)
      base.preference :icon_name, :string, default: 'cheque'
      base.belongs_to :vendor, class_name: 'Spree::Vendor', optional: true, inverse_of: :payment_methods

      def base.vpago_payments
        [
          Spree::PaymentMethod::TYPE_PAYWAY_V2,
          Spree::PaymentMethod::TYPE_PAYWAY,
          Spree::PaymentMethod::TYPE_WINGSDK,
          Spree::PaymentMethod::TYPE_ACLEDA,
          Spree::PaymentMethod::TYPE_ACLEDA_MOBILE,
          Spree::PaymentMethod::TYPE_VATTANAC,
          Spree::PaymentMethod::TYPE_VATTANAC_MINI_APP,
          Spree::PaymentMethod::TYPE_TRUE_MONEY
        ]
      end
    end

    def enable_payout? = support_payout?
    def enable_pre_auth? = support_pre_auth? && self[:enable_pre_auth]
    def support_payout? = false
    def support_pre_auth? = false

    # TODO: we have already implement purchase for payway_v2.
    # make sure to implement this on other payment method as well.
    def purchase(_amount, _source, _gateway_options = {})
      ActiveMerchant::Billing::Response.new(true, 'Payway Gateway: Success')
    end

    def default_payout_profile
      nil
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

    def type_vattanac_mini_app?
      type == Spree::PaymentMethod::TYPE_VATTANAC_MINI_APP
    end

    def type_true_money?
      type == Spree::PaymentMethod::TYPE_TRUE_MONEY
    end

    def type_check?
      type == 'Spree::PaymentMethod::Check'
    end

    # @return [String] the image asset path, e.g. "payment_logos/payway-abapay-khqr.png"
    def payment_icon_path
      "payment_logos/#{preferred_icon_name.tr('_', ' ').parameterize}.png"
    end
  end
end

Spree::PaymentMethod.prepend(Vpago::PaymentMethodDecorator) unless Spree::PaymentMethod.included_modules.include?(Vpago::PaymentMethodDecorator)
