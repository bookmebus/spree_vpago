module Spree
  class Gateway::AcledaMobile < PaymentMethod
    preference :partner_id, :string
    preference :data_encryption_key, :string

    # partial to render the gateway.
    def method_type
      "acleda_mobile"
    end

    def payment_source_class
      Spree::VpagoPaymentSource
    end

    def payment_profiles_supported?
      false
    end

    # Custom PaymentMethod/Gateway can redefine this method to check method
    # availability for concrete order.
    def available_for_order?(_order)
      true
    end

    # force to purchase instead of authorize
    def auto_capture?
      true
    end

    def process(money, source, gateway_options)
      Rails.logger.debug{"About to create payment for order #{gateway_options[:order_id]}"}
      # First of all, invalidate all previous tranx orders to prevent multiple paid orders
      # source.save!
      ActiveMerchant::Billing::Response.new(true, 'Order created')
    end

    def cancel(response_code)
      # we can use this to send request to payment gateway api to cancel the payment ( void )
      # currently Payway does not support to cancel the gateway
      
      # in our case don't do anything
      ActiveMerchant::Billing::Response.new(true, 'Mollie order has been cancelled.')
    end
  end
end
