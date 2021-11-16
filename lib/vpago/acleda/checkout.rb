module Vpago
  module Acleda
    class Checkout < Base
      attr_accessor :error_message

      def initialize(payment, options={})
        super

        @error_message = nil
        start_connection
        update_payment_source
      end

      def start_connection
        @response = create_session

        if @response.status != 500 && @response.status != 200
          @error_message = 'Sever Error'
        elsif @response.status == 500 ## mostly when passing wrong parameter name
          @error_message = @response.body
        elsif @response.status == 200 && json_response['result']['code'] != 0 ## mostly when passing invalid payload, wrong loginId, etc.
          @error_message = json_response['result']['errorDetails']
        end
      end

      def update_payment_source
        return if failed?

        @payment.source.update_column(:transaction_id, json_response['result']['xTran']['paymentTokenid'])
      end

      def json_response
        @json ||= JSON.parse(@response.body)
      end

      def create_session
        con = Faraday::Connection.new(url: host)

        con.post(create_session_path) do |request|
          request.headers["Content-Type"] = "application/json"
          request.body = create_session_requst_body.to_json
        end
      end

      def failed?
        @error_message.present?
      end

      def create_session_requst_body
        {
          loginId: login_id,
          password: password,
          merchantID: merchant_id,
          signature: signature,
          xpayTransaction: {
            txid: payment_number,
            invoiceid: order_number,
            purchaseAmount: amount_with_fee,
            purchaseCurrency: 'USD',
            purchaseDate: purchase_date,
            purchaseDesc: 'items',
            item: '1',
            quantity: '1',
            expiryTime: expiry_time
          }
        }
      end

      def create_session_path
        "/VETDIGITAL/XPAYConnectorServiceInterfaceImplV2/XPAYConnectorServiceInterfaceImplV2RS/openSessionV2"
      end

      def gateway_params
        return {} if failed?

        {
          merchantID: merchant_id,
          sessionid: json_response['result']['sessionid'],
          paymenttokenid: json_response['result']['xTran']['paymentTokenid'],
          description: 'items',
          expirytime: expiry_time,
          amount: amount_with_fee,
          quantity: '1',
          Item: '1',
          invoiceid: order_number,
          currencytype: 'USD',
          transactionID: payment_number,
          successUrlToReturn: success_url,
          errorUrl: error_url
        }
      end
    end
  end
end
