require 'faraday'

module Vpago
  module Acleda
    class TransactionStatus < Base
      attr_accessor :error_message
      attr_accessor :result

      def call
        prepare
        process
      end

      def prepare
        @error_message = nil
        @result = nil
      end

      def process
        @response = check_acleda_payment_status

        if @response.status == 200
          if json_response['result']['code'] != 0 
            fail!(json_response['result']['errorDetails'])
          else
            @result = json_response
          end
        else
          fail!(@response.body)
        end
      end

      def request_payload
        payment_token_id = @payment.source.transaction_id

        {
          loginId: login_id,
          password: password,
          merchantName: merchant_name,
          signature: signature,
          merchantId: merchant_id,
          paymentTokenid: payment_token_id
        }
      end

      def check_acleda_payment_status
        con = Faraday::Connection.new(url: host)

        con.post(check_status_path) do |request|
          request.headers["Content-Type"] = "application/json"
          request.body = request_payload.to_json
        end
      end

      def check_status_path
        ENV['ACLEDA_CHECK_STATUS_PATH']
      end

      def json_response
        @json ||= JSON.parse(@response.body)
      end

      def fail!(message)
        @error_message = message
      end

      def success?
        @error_message == nil
      end
    end
  end
end
