module Vpago
  module Vattanac
    class TransactionStatus < Base
      def call
        @response = post(check_transaction_url, payload)
      end

      def json_response
        @response
      end

      def success?
        @response.dig('data', 'status') == 'SUCCESS'
      end

      private

      def payload
        { transactionId: payment_number }
      end
    end
  end
end
