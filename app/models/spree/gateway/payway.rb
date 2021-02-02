module Spree
  class Gateway::Payway < PaymentMethod
    # 'abapay', 'cards'
    preference :endpoint, :string
    preference :api_key, :string
    preference :merchant_id, :string
    preference :return_url, :string
    preference :continue_success_url, :string
    preference :payment_option, :string
    preference :transaction_fee_fix, :string
    preference :transaction_fee_percentage, :string

    # Only enable one-click payments if spree_auth_devise is installed
    # def self.allow_one_click_payments?
    #   Gem.loaded_specs.key?('spree_auth_devise')
    # end

    def payment_source_class
      Spree::VpagoPaymentSource
    end

    def card_type
      Vpago::Payway::CARD_TYPES.index(preferences[:payment_option]) == nil ? Vpago::Payway::CARD_TYPE_ABAPAY : preferences[:payment_option]
    end

    def is_card?
      preferences[:payment_option] == Vpago::Payway::CARD_TYPE_CARDS
    end

    def is_aba?
      preferences[:payment_option] == Vpago::Payway::CARD_TYPE_ABAPAY
    end

    # partial to render the gateway.
    def method_type
      "payment_payway"
    end

    def actions
      %w[credit]
    end

    def available_for_order?(_order)
      true
    end

    # Custom PaymentMethod/Gateway can redefine this method to check method
    # availability for concrete order.
    def available_for_order?(_order)
      true
    end

    def auto_capture?
      true
    end

    def process(money, source, gateway_options)
      Rails.logger.debug{"About to create payment for order #{gateway_options[:order_id]}"}
      # First of all, invalidate all previous tranx orders to prevent multiple paid orders
      # source.save!
      ActiveMerchant::Billing::Response.new(true, 'Order created')

    end

  end

end