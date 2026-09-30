require 'faraday'

# API documentation:
# https://developer.payway.com.kh/check-transaction-14530826e0
module Vpago
  module PaywayV2
    class TransactionStatusV2 < Base
      def call
        @response = check_remote_status
      end

      # 00 : Success!
      # 5 : Invalid hash
      # 6 : Transaction not found
      # 8 : Invalid merchant profile
      # 11 : Internal server error
      # 429 : Reach request limit
      def status_code
        status_data = json_response['status']
        return nil unless status_data.is_a?(Hash)

        status_data['code']&.to_s
      end

      # APPROVED : Transaction successfully completed with the full purchase amount.
      # PRE-AUTH : Transaction successfully processed with a pre-authorization hold on funds pending final capture.
      # REFUNDED : Transaction has been fully or partially refunded.
      # PENDING : Transaction is awaiting payment completion by the payer.
      # DECLINED : Transaction has been declined.
      # CANCELLED : Merchant canceled the pre-authorization or closed the transaction.
      def payment_status
        data = json_response['data']
        return nil unless data.is_a?(Hash)

        data['payment_status']
      end

      def success?
        %w[APPROVED PRE-AUTH].include?(payment_status)
      end

      # request failed does not mean payment failed.
      # but it failed when status is failed.
      def pending?
        %w[PENDING].include?(payment_status)
      end

      def failed?
        %w[5 6 8].include?(status_code) || %w[DECLINED CANCELLED].include?(payment_status)
      end

      def check_remote_status
        conn = Faraday::Connection.new do |faraday|
          faraday.request :url_encoded
          faraday.options.open_timeout = Vpago::HttpTimeouts::OPEN_TIMEOUT
          faraday.options.timeout = Vpago::HttpTimeouts::TIMEOUT
        end

        data = {
          req_time: req_time,
          merchant_id: merchant_id,
          tran_id: transaction_id,
          hash: checker_hmac
        }

        conn.post(check_transaction_url, data)
      end

      def error_message
        status_data = json_response['status']
        return nil unless status_data.is_a?(Hash)

        status_data['message']
      end

      def json_response
        @json_response ||= begin
          JSON.parse(@response.body)
        rescue JSON::ParserError
          {}
        end
      end

      def checker_hmac
        data = "#{req_time}#{merchant_id}#{transaction_id}"
        hash = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha512'), api_key, data))

        # somehow php counter part are not able to decode if the \n present.
        hash.delete("\n")
      end

      def check_transaction_url
        "#{host}/api/payment-gateway/v1/payments/check-transaction-2"
      end
    end
  end
end
