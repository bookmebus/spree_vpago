module Vpago
  module AcledaMobile
    class Base
      include Vpago::PaymentAmountCalculator

      def initialize(payment, options={})
        @options = options
        @payment = payment
      end

      def payment_number
        @payment.number
      end

      def encryption_key
        @payment.payment_method.preferences[:data_encryption_key]
      end

      def partner_id
        @payment.payment_method.preferences[:partner_id]
      end
    end
  end
end
