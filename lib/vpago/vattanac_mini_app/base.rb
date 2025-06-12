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
        ENV['VATTANAC_PARTNER_CODE'].presence
      end

      def refund_url
        ENV['VATTANAC_REFUND_URL'].presence
      end
    end
  end
end
