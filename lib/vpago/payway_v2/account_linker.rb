require 'faraday'

module Vpago
  module PaywayV2
    class AccountLinker
      def call
        context.response = response
      end

      def response
        conn = Faraday::Connection.new do |faraday|
          faraday.request :url_encoded
        end

        data = {
          request_time: req_time,
          merchant_id: merchant_id,
          return_params: nil,
          return_url: return_url,
          hash: hash
        }
        conn.post(link_account_url, data)
      end

      def link_account_url
        "#{host}#{ENV.fetch('PAYWAY_V2_LINK_ACCCOUNT_PATH')}"
      end

      def merchant_id
        ENV.fetch('MERCHANT_ID')
      end

      def req_time
        Time.current.strftime('%Y%m%d%H%M%S')
      end

      def return_url
        preferred_return_url = ENV.fetch('PAYWAY_V2_LINK_ACCOUNT_CALLBACK_URL', nil)
        return nil if preferred_return_url.blank?

        Base64.encode64(preferred_return_url).delete("\n")
      end

      def hash
        hash_data = "#{merchant_id}#{req_time}"
        Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha512'), api_key, hash_data))
      end

      def api_key
        ENV.fetch('API_KEY')
      end
    end
  end
end
