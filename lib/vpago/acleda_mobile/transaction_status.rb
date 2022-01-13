require 'faraday'

module Vpago
  module AcledaMobile
    class TransactionStatus < Base
      attr_accessor :error_message
      attr_accessor :result

      ##TO DO: remove payment_token_id when check transaction status api ready
      def call(payment_token_id=nil)
        prepare
        process(payment_token_id)
      end

      def prepare
        @error_message = nil
        @result = nil
      end

      def process(payment_token_id)
        @result = {
          ErrorCode: '200',
          ErrorDescription: 'Success',
          TransactionId: payment_number,
          PaymentTokenId: payment_token_id,
          Amount: '',
          Currency: 'USD'
        }
      end

      def success?
        @error_message == nil
      end
    end
  end
end
