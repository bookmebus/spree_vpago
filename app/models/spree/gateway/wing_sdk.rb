module Spree
  class Gateway::WingSdk < PaymentMethod
    preference :username, :string
    preference :biller_code, :string
    preference :rest_api_key, :string
    preference :sandbox, :boolean
    preference :host, :string
    preference :return_url, :string
    preference :transaction_fee_fix, :string
    preference :transaction_fee_percentage, :string

    ## for basic authentication on checking transaction on vtenh
    preference :basic_auth_username, :string
    preference :basic_auth_password, :string

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
      ActiveMerchant::Billing::Response.new(true, 'Wing Sdk order has been cancelled.')
    end
  end
end
