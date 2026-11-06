module Spree
  # Wing Mini App payment method (doPayment). Wing pushes settlement to our webhook,
  # where Vpago::PaymentFinder checks the secretKey and the amount/currency match
  # before storing transaction_response — the only place that is verified.
  class Gateway::WingMiniApp < PaymentMethod
    def method_type
      'wing_mini_app'
    end

    # Read from Wing's mini app row (WingMiniApp::Config), not a payment method preference:
    # login verifies against the same pair, and a second source could sign payments as a
    # different partner — a mismatch that first surfaces at the webhook, after the debit.
    def app_id
      SpreeCmCommissioner::WingMiniApp::Config.app_id
    end

    def secret_api_key
      SpreeCmCommissioner::WingMiniApp::Config.secret_api_key
    end

    def payment_source_class
      Spree::VpagoPaymentSource
    end

    def auto_capture?
      true
    end

    # override
    def purchase(_amount, _source, gateway_options = {})
      _, payment_number = gateway_options[:order_id].split('-')
      payment = Spree::Payment.find_by(number: payment_number)
      response = payment&.transaction_response || {}

      params = { payment_response: response }

      # A present transaction_response is PaymentFinder having already verified this
      # settlement, so there is nothing left to check.
      if response.present?
        ActiveMerchant::Billing::Response.new(true, 'Wing Mini App: Purchased', params)
      else
        ActiveMerchant::Billing::Response.new(false, 'Wing Mini App: Purchasing Failed', params)
      end
    end

    # override
    def void(_response_code, _gateway_options)
      ActiveMerchant::Billing::Response.new(true, 'Wing Mini App order has been voided.')
    end

    # override
    # Wing documents no refund API, so this fails rather than returning a no-op success:
    # refunds stay manual with Wing until they publish one.
    def cancel(_response_code, _payment)
      ActiveMerchant::Billing::Response.new(false, 'Wing Mini App: cancel is not supported — no Wing refund API is documented yet.')
    end
  end
end
