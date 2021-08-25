module Vpago
  module WingSdk
    class TransactionStatusResponse
      attr_accessor :result

      def initialize(wing_payment_source)
        @wing_payment_source = wing_payment_source
        @result = {}
      end

      def call
        return if !@wing_payment_source.preferred_wing_response.present?

        wing_response = @wing_payment_source.preferred_wing_response.with_indifferent_access

        @result = {
          response_code: 200,
          response_msg: 'Transaction success',
          customer_name: wing_response["customer_name"],
          amount: wing_response["amount"],
          currency: wing_response["currency"],
          partner_txn_id: @wing_payment_source.payment.number,
          transaction_id: wing_response["transaction_id"],
          transaction_date: wing_response["transaction_date"]
        }
      end

      def success?
        @result.present?
      end
    end
  end
end
