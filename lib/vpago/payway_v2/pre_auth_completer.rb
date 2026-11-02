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
        connection.post(complete_url, request_data)
      end

      # Without timeouts Net::HTTP waits up to 60s to connect and 60s to read, holding the
      # payment_processing worker thread that also completes every other customer's checkout.
      def connection
        Faraday::Connection.new do |faraday|
          faraday.request :url_encoded
          faraday.options.open_timeout = Vpago::HttpTimeouts::OPEN_TIMEOUT
          faraday.options.timeout = Vpago::HttpTimeouts::TIMEOUT
        end
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
        merchant_auth = {
          'mc_id' => merchant_id,
          'tran_id' => transaction_id,
          'complete_amount' => amount.to_s
        }

        merchant_auth['payout'] = payout unless payout.nil?
        merchant_auth.to_json
      end

      def merchant_auth_encryption
        @merchant_auth_encryption ||= Vpago::PayoutProfiles::Payway::OpenSslEncrypter.new(
          content: merchant_auth,
          rsa_public_key: public_key
        ).call
      end

      def complete_url
        "#{host}/api/merchant-portal/merchant-access/online-transaction/pre-auth-completion"
      end

      # A non-JSON body (e.g. an HTML 502 page) must be a normal failure. Raising here would skip
      # Spree's failure handling and leave the payment without any log entry.
      def success?
        status = json_response.is_a?(Hash) ? json_response['status'] : nil
        status.is_a?(Hash) && status['code'].to_s == '00'
      end

      def json_response
        return @payment.pre_auth_response if @payment.pre_auth_response.present?

        @json_response ||= begin
          JSON.parse(@response.body)
        rescue JSON::ParserError
          # Kept so the payment's log entry shows what the gateway actually returned.
          { 'raw_body' => @response.body.to_s[0, 2000], 'http_status' => @response.status }
        end
      end
    end
  end
end
