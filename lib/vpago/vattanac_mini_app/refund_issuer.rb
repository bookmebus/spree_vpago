module Vpago
  module VattanacMiniApp
    class RefundIssuer < Base
      attr_reader :response

      def call
        raw_response = send_refund_request
        @response = handle_response(raw_response)
      end

      def success?
        @success
      end

      def send_refund_request
        Faraday.post(refund_url) do |req|
          req.headers['Content-Type'] = 'application/json'
          req.headers['Partner-Code'] = partner_code
          req.body = {
            data: Vpago::VattanacMiniAppDataHandler.new.encrypted_data(refund_payload)
          }.to_json
        end
      end

      def handle_response(response)
        body = parse_json(response.body)

        if body['status'] == 'SUCCESS'
          json = Vpago::VattanacMiniAppDataHandler.new.decrypt_data(body['data'])
          @success = true
          json
        else
          @success = false
          body
        end
      end

      def refund_payload
        {
          transactionId: @payment.transaction_response["transactionId"],
          paymentId:     @payment.transaction_response["paymentId"],
          amount:        @payment.transaction_response["amount"],
          currency:      'USD'
        }
      end

      def parse_json(raw)
        JSON.parse(raw)
      rescue JSON::ParserError => e
        raise StandardError, "Invalid JSON: #{e.message}"
      end
    end
  end
end
