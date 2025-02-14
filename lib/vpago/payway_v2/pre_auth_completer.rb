require 'faraday'

module Vpago
  module PaywayV2
    class PreAuthCompleter < Base
      def call
        return if completed? || cancelled?

        @response = pre_auth_response
        save_response if success?
      end

      def completed? = @payment.pre_auth_response['transaction_status'] == 'COMPLETED'
      def cancelled? = @payment.pre_auth_response['transaction_status'] == 'CANCELLED'

      def save_response
        @payment.update(pre_auth_response: json_response)
      end

      def pre_auth_response
        conn = Faraday::Connection.new do |faraday|
          faraday.request :url_encoded
        end

        conn.post(complete_url, request_data)
      end

      def request_data
        {
          request_time: req_time,
          merchant_id: merchant_id,
          merchant_auth: merchant_auth_encryption,
          hash: hash_data
        }
      end

      def hash_data
        data = "#{merchant_auth_encryption}#{req_time}#{merchant_id}"
        Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha512'), api_key, data))
      end

      def merchant_auth
        {
          'mc_id' => merchant_id,
          'tran_id' => transaction_id,
          'complete_amount' => amount.to_s
        }.to_json
      end

      def merchant_auth_encryption
        @merchant_auth_encryption ||= Vpago::PayoutProfiles::Payway::OpenSslEncrypter.new(
          content: merchant_auth,
          rsa_public_key: public_key
        ).call
      end

      def complete_url
        "#{host}#{ENV.fetch('PAYWAY_V2_PRE_AUTH_COMPLETE_PATH')}"
      end

      def success?
        json_response['status']['code'] == '00'
      end

      def json_response
        return @payment.pre_auth_response if @payment.pre_auth_response.present?

        @json_response ||= begin
          JSON.parse(@response.body)
        rescue JSON::ParserError
          {}
        end
      end
    end
  end
end
