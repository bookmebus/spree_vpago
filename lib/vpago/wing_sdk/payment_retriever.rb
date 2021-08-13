module Vpago
  module WingSdk
    class PaymentRetriever
      attr_accessor :payment

      def initialize(rest_api_key, wing_response)
        @rest_api_key = rest_api_key
        @wing_response = wing_response
      end

      def call
        response = JSON.parse(prepare_decrypt)

        @payment = ::Spree::Payment.find_by(number: response[:remark])
      end

      def prepare_decrypt
        hash = Digest::SHA256.hexdigest(@rest_api_key)
        # $key = pack('H*', $hash)
        key = [hash].pack('H*')
        iv  = 0.chr * 16
        encrypted = Base64.decode64(@wing_response)
    
        cipher = OpenSSL::Cipher.new('AES-256-CBC')
        cipher.decrypt
        cipher.key = key
        cipher.iv  = iv
        crypt = cipher.update(encrypted)
        crypt << cipher.final
        crypt
      end
    end
  end
end
