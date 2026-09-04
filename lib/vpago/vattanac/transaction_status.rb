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

      def error_message
        @response.dig('msgEntity', 'message') || @response.dig('data', 'message') || 'Unknown error'
      end

      # msgEntity.code is the API-envelope result code ("0" = call succeeded; check
      # data.status for the actual transaction state). Any other code is a gateway-level
      # error with no transaction data (e.g. "03" / "Transaction not found") and is
      # treated as terminal failure.
      def failed?
        @response.dig('msgEntity', 'code').to_s != '0'
      end

      def pending?
        !success? && !failed?
      end

      private

      def payload
        { transactionId: payment_number }
      end
    end
  end
end