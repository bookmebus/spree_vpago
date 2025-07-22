module Vpago
  module TrueMoney
    class TransactionStatus < Base
      def call
        @response = Faraday.get(check_transaction_url, nil, default_headers)
      end

      def success?
        response_code == '000001'
      end

      def response_code
        json_response.dig('status', 'code')
      end

      def signature_input
        timestamp.to_s
      end

      def json_response
        @json_response ||= parse_json(@response.body)
      end
    end
  end
end
