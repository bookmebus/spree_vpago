require 'openssl'

module Vpago
  module PayoutProfiles
    module Payway
      class OpenSslEncrypter
        attr_reader :content, :rsa_public_key

        def initialize(content:, rsa_public_key:)
          @content = content
          @rsa_public_key = OpenSSL::PKey::RSA.new(rsa_public_key)
        end

        def call
          # Assumes 1024 bit key and encrypts in chunks.
          maxlength = 117
          output = ''

          source = content.dup
          while source != ''
            input = source.slice!(0, maxlength)
            encrypted = rsa_public_key.public_encrypt(input)
            output += encrypted
          end

          Base64.strict_encode64(output)
        end
      end
    end
  end
end
