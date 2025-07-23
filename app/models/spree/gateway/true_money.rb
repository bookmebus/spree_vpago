module Spree
  class Gateway::TrueMoney < PaymentMethod
    preference :check_transaction_url, :string
    preference :refund_url, :string
    preference :generate_payment_url, :string
    preference :access_token_url, :string

    preference :client_id, :string
    preference :client_secret, :string
    preference :private_key, :text
    preference :return_url_scheme, :string
    preference :android_package_name, :string
    preference :redirect_type, :string

    def method_type
      'true_money'
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

    # override
    def void(_response_code, gateway_options)
      _, payment_number = gateway_options[:order_id].split('-')
      payment = Spree::Payment.find_by(number: payment_number)

      if payment.true_money_payment?
        params = {}
        success, params[:refund_response] = true_money_refund(payment)

        if success
          ActiveMerchant::Billing::Response.new(true, 'True money Gateway: successfully canceled.', params)
        else
          ActiveMerchant::Billing::Response.new(false, 'True money Gateway: Failed to canceleed', params)
        end
      else
        ActiveMerchant::Billing::Response.new(true, 'True money Gateway: Payment has been voided.')
      end
    end

    def true_money_refund(payment)
      refund_issuer = Vpago::TrueMoney::RefundIssuer.new(payment, {})
      refund_issuer.call

      [refund_issuer.success?, refund_issuer.parsed_response]
    end

    def cancel(_response_code, _payment)
      # we can use this to send request to payment gateway api to cancel the payment ( void )
      # currently True money does not support to cancel the gateway

      # in our case don't do anything
      ActiveMerchant::Billing::Response.new(true, '')
    end

    private

    def check_transaction(payment)
      checker = Vpago::TrueMoney::TransactionStatus.new(payment)
      checker.call
      checker
    end
  end
end
