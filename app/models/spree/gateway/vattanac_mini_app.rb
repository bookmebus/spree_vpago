module Spree
  class Gateway::VattanacMiniApp < PaymentMethod
    preference :partner_code, :string
    preference :refund_url, :string

    def method_type
      'vattanac_mini_app'
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

      params = {}

      params[:payment_response] = payment.transaction_response

      if payment.transaction_response['status'] == 'SUCCESS'
        ActiveMerchant::Billing::Response.new(true, 'Payway Gateway: Purchased', params)
      else
        ActiveMerchant::Billing::Response.new(false, 'Payway Gateway: Purchasing Failed', params)
      end
    end

    # override
    def void(_response_code, _gateway_options)
      ActiveMerchant::Billing::Response.new(true, 'Vattanac order has been voided.')
    end

    # override
    def cancel(_response_code, payment)
      if payment.vattanac_mini_app_payment?
        params = {}
        success, params[:refund_response] = vattanac_mini_app_refund(payment)

        if success
          ActiveMerchant::Billing::Response.new(true, 'Payway Gateway: successfully canceled.', params)
        else
          ActiveMerchant::Billing::Response.new(false, 'Payway Gateway: Failed to canceleed', params)
        end
      else
        ActiveMerchant::Billing::Response.new(true, 'Payway Gateway: Payment has been voided.')
      end
    end

    def vattanac_mini_app_refund(payment)
      refund_issuer = Vpago::VattanacMiniApp::RefundIssuer.new(payment, {})
      refund_issuer.call

      [refund_issuer.success?, refund_issuer.response]
    end
  end
end
