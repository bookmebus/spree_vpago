module Vpago
  module PayoutProfiles
    module Payway
      class PayoutProfileRequestParamsBuilder
        attr_reader :request_time, :profile

        def initialize(request_time, profile)
          @request_time = request_time
          @profile = profile
        end

        def api_key = profile.preferred_api_key
        def rsa_public_key = profile.preferred_rsa_public_key
        def merchant_id = profile.preferred_merchant_id
        def payee = profile.preferred_payee
        def status = profile.active ? '1' : '0'

        def formatted_request_time
          request_time.strftime("%Y%m%d%H%M%S")
        end

        def merchant_auth_data
          {
            'mc_id' => merchant_id,
            'payee' => payee,
            'status' => status
          }.to_json
        end

        def merchant_auth
          @merchant_auth ||= OpenSslEncrypter.new(
            content: merchant_auth_data,
            rsa_public_key: rsa_public_key
          ).call
        end


        def hash_data
          "#{formatted_request_time}#{merchant_auth}"
        end

        def encoded_hash
          digest_name = OpenSSL::Digest.new('sha512')
          hash = OpenSSL::HMAC.digest(digest_name, api_key, hash_data)
          Base64.strict_encode64(hash)
        end

        def request_params
          {
            request_time: formatted_request_time,
            merchant_id: merchant_id,
            merchant_auth: merchant_auth,
            hash: encoded_hash,
          }
        end
      end
    end
  end
end
