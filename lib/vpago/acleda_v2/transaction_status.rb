require 'faraday'

module Vpago
  module AcledaV2
    class TransactionStatus < Base
      # Terminal failure indicators in result.errorDetails. The PDFs only document
      # code 0 / "SUCCESS"; decline/expiry wording is conservative and should be
      # confirmed against real responses during UAT. Anything not success and not
      # terminal is treated as pending so the poller keeps trying.
      FAILED_ERROR_DETAILS = %w[EXPIRED DECLINED CANCELLED FAILED REJECTED].freeze

      def call
        @response = check_remote_status
        self
      end

      def json_response
        @json_response ||= parse_json(@response.body)
      end

      def result
        json_response['result'] || {}
      end

      def result_code
        result['code']
      end

      def error_message
        result['errorDetails']
      end

      def success?
        http_success? && result_code == 0 && error_message == 'SUCCESS'
      end

      def failed?
        return false unless http_success?

        FAILED_ERROR_DETAILS.include?(error_message.to_s.upcase)
      end

      def pending?
        !success? && !failed?
      end

      private

      def http_success?
        @response&.status == 200
      end

      def token
        @payment.source&.transaction_id
      end

      def check_remote_status
        conn = Faraday::Connection.new

        conn.post(get_txn_status_url) do |request|
          request.headers['Content-Type'] = Base::CONTENT_TYPE_JSON
          request.body = payload.to_json
        end
      end

      # NOTE: getTxnStatus uses merchantId (lowercase d) and an extra merchantName
      # field. merchantName is NOT part of the HMAC message.
      def payload
        {
          loginId: login_id,
          password: password,
          merchantId: merchant_id,
          merchantName: merchant_name,
          hash: txn_status_hash(token),
          paymentTokenid: token
        }
      end
    end
  end
end
