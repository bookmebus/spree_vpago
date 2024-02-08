module Spree
  class Gateway::Acleda < PaymentMethod
    preference :payment_expiry_time_in_mn, :integer
    preference :host, :string
    preference :login_id, :string
    preference :password, :string
    preference :merchant_id, :string
    preference :merchant_name, :string
    preference :signature, :string
    preference :deeplink_partner_id, :string
    preference :deeplink_data_encryption_key, :string
    preference :success_url, :string
    preference :error_url, :string
    preference :other_url, :string
    preference :acleda_company_name, :string
    preference :acleda_payment_card, :integer

    TYPES = %w[KHQR XPAY-MPGS].freeze
    preference :acleda_type, :string

    def xpay_mpgs?
      preferred_acleda_type == 'XPAY-MPGS'
    end

    def khqr?
      preferred_acleda_type == 'KHQR'
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
      ActiveMerchant::Billing::Response.new(true, 'Acleda order has been cancelled.')
    end
  end
end
