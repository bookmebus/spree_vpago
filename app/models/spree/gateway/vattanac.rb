module Spree
  class Gateway::Vattanac < PaymentMethod
    preference :generate_payment_url, :string
    preference :access_token_url, :string
    preference :check_transaction_url, :string

    preference :username, :string
    preference :password, :string
    preference :merchant_id, :string
    preference :payment_type, :string, default: 'GOLF_TICKET'
    preference :open_type, :string, default: 'both'

    def method_type
      'vattanac'
    end

    def payment_source_class
      Spree::VpagoPaymentSource
    end

    # force to purchase instead of authorize
    def auto_capture?
      true
    end

    # override
    # purchase is used when pre auth disabled
    def purchase(_amount, _source, gateway_options = {})
      _, payment_number = gateway_options[:order_id].split('-')
      payment = Spree::Payment.find_by(number: payment_number)

      checker = check_transaction(payment)
      payment.update(transaction_response: checker.json_response)

      success = checker.success?
      params = {}

      params[:payment_response] = payment.transaction_response

      if success
        ActiveMerchant::Billing::Response.new(true, 'Payway Gateway: Purchased', params)
      else
        ActiveMerchant::Billing::Response.new(false, 'Payway Gateway: Purchasing Failed', params)
      end
    end

    def vattanac_refund(payment)
      refund_issuer = Vpago::Vattanac::RefundIssuer.new(payment, {})
      refund_issuer.call

      [refund_issuer.success?, refund_issuer.parsed_response]
    end

    def cancel(_response_code, _payment)
      # we can use this to send request to payment gateway api to cancel the payment ( void )
      # currently Vattanac does not support to cancel the gateway

      # in our case don't do anything
      ActiveMerchant::Billing::Response.new(true, '')
    end

    private

    def check_transaction(payment)
      checker = Vpago::Vattanac::TransactionStatus.new(payment)
      checker.call
      checker
    end
  end
end
