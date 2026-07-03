module Spree
  class Gateway::AcledaV2 < PaymentMethod
    MODES = %w[khqr card deeplink].freeze

    # BOOKMEPLUS — sent as the "merchantName" field in getTxnStatus requests
    preference :merchant_name, :string
    # e.g. https://epaymentuat.acledabank.com.kh/BOOKMEPLUS/XPAYConnectorServiceInterfaceImplV2/XPAYConnectorServiceInterfaceImplV2RS
    preference :xpay_service_base_url, :string
    # e.g. https://epaymentuat.acledabank.com.kh/BOOKMEPLUS/paymentPage.jsp
    preference :payment_page_url, :string
    preference :merchant_id, :string
    preference :login_id, :string
    preference :password, :string
    preference :secret, :string # HMAC-SHA512 key
    preference :payment_expiry_time_in_mn, :integer, default: 5
    preference :acleda_v2_mode, :string, default: 'khqr'

    validates :preferred_acleda_v2_mode, inclusion: { in: MODES }

    def khqr?
      preferred_acleda_v2_mode == 'khqr'
    end

    def card?
      preferred_acleda_v2_mode == 'card'
    end

    def deeplink?
      preferred_acleda_v2_mode == 'deeplink'
    end

    # KHQR (Scan with Bank under Bakong) = "0"; Credit/debit card = "1"
    def payment_card_value
      card? ? '1' : '0'
    end

    # override: partial to render in admin
    def method_type
      'acleda_v2'
    end

    # override
    def payment_source_class
      Spree::VpagoPaymentSource
    end

    # override
    def payment_profiles_supported?
      false
    end

    # override
    def available_for_order?(_order)
      true
    end

    # override: process! -> purchase! immediately (no pre-auth for ACLEDA V2)
    def auto_capture?
      true
    end

    # override
    # mirror PayWay V2: gateway_options[:order_id] == "<order_number>-<payment_number>"
    def purchase(_amount, _source, gateway_options = {})
      _, payment_number = gateway_options[:order_id].split('-')
      payment = Spree::Payment.find_by(number: payment_number)

      checker = check_transaction(payment)
      payment.update(transaction_response: checker.json_response)

      params = { check: { response: checker.json_response } }

      if checker.success?
        ActiveMerchant::Billing::Response.new(true, 'Acleda V2: Purchased', params)
      else
        ActiveMerchant::Billing::Response.new(false, 'Acleda V2: Purchasing Failed', params)
      end
    end

    # Defining check_transaction makes support_check_transaction_api? true,
    # enabling the /vpago_payments/check_transaction poller.
    def check_transaction(payment)
      checker = Vpago::AcledaV2::TransactionStatus.new(payment)
      checker.call
      checker
    end

    # override
    def cancel(_response_code, _payment = nil)
      ActiveMerchant::Billing::Response.new(true, 'Acleda V2: Payment has been canceled.')
    end
  end
end
