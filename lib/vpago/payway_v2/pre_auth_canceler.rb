require 'faraday'

module Vpago
  module PaywayV2
    class PreAuthCanceler < PreAuthCompleter
      # override
      def pre_auth_response
        conn = Faraday::Connection.new do |faraday|
          faraday.request :url_encoded
        end

        conn.post(cancel_url, request_data)
      end

      def request_data
        {
          request_time: req_time,
          merchant_id: merchant_id,
          merchant_auth: merchant_auth_encryption,
          hash: hash_data
        }
      end

      # override
      def hash_data
        data = "#{merchant_id}#{merchant_auth_encryption}#{req_time}"
        Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha512'), api_key, data))
      end

      # override
      def merchant_auth
        {
          'mc_id' => merchant_id,
          'tran_id' => transaction_id
        }.to_json
      end

      def cancel_url
        "#{host}#{ENV.fetch('PAYWAY_V2_PRE_AUTH_CANCEL_PATH')}"
      end
    end
  end
end
