module Vpago
  module AcledaMobile
    class CallbackValidator
      # {
      #   "TransactionId": "REF0361472663",
      #   "PaymentTokenId": "16de81d4-b5ef-ef59-16de-81d4b5efef59",
      #   "TxnAmount": "30",
      #   "SenderName": "Test User",
      #   "SignedHash": "c5b9be690bde7dc8a0abebb1a45c0850359540a4977aecd4cdf13e15a2edfe79",
      #   }
      def initialize(options)
        @options = options
      end

      def call
        valid?
      end

      def secret_key
        ENV['ACLEDA_MOBILE_SECRET_HASH_KEY']
      end

      def valid?
        return false if secret_key.blank?

        hmac_hash == @options[:SignedHash]
      end

      def hmac_hash
        key = secret_key

        message = "#{@options[:TransactionId]} #{@options[:PaymentTokenId]} #{@options[:TxnAmount]}"
  
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), key, message)
      end
    end
  end
end
