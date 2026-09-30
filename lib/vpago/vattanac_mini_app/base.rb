module Vpago
  module VattanacMiniApp
    class Base
      def initialize(payment, options = {})
        @options = options
        @payment = payment
      end

      def payload
        {
          paymentId: payment_id,
          amount: amount,
          currency: currency || 'USD',
          expiredIn: expired_at
        }
      end

      def encrypt_data(payload)
        SpreeCmCommissioner::AesEncryptionService.encrypt(payload.to_json, aes_key)
      end

      def amount
        @payment.amount
      end

      def payment_id
        @payment.number
      end

      def currency
        'USD'
      end

      def transaction_id
        @payment.number
      end

      def expired_at
        (Time.now + 30.minutes).to_i * 1000
      end

      def partner_code
        @payment.payment_method.preferred_partner_code
      end

      def refund_url
        @payment.payment_method.preferred_refund_url
      end
    end
  end
end
