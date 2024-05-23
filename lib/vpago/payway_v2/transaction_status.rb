require 'faraday'

module Vpago
  module PaywayV2
    class TransactionStatus < Base
      # status:
      # 0 – Approved, PRE_AUTH, PREAUTH_APPROVED
      # 1 – Created
      # 2 – Pending
      # 3 – Declined
      # 4 – Refunded
      # 5 – Wrong Hash
      # 11 – Other Server-side Error
      def call
        @response = check_remote_status
      end

      def status
        json_response['status']&.to_s
      end

      def success?
        status == '0'
      end

      # request failed does not mean payment failed.
      # but it failed when status is failed.
      def pending?
        %w(1 2).include?(status)
      end
    
      def failed?
        %w(3 4 5).include?(status)
      end

      def check_remote_status
        conn = Faraday::Connection.new do |faraday|
          faraday.request  :url_encoded
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
        json_response['description'].presence
      end

      def json_response
        @json ||= begin
          JSON.parse(@response.body)
        rescue JSON::ParserError
          {}
        end
      end

      def build_payout_profile_payments
        payouts_response = json_response['payout']

        return [] if payouts_response.nil? || !payouts_response.is_a?(Array) || payouts_response.empty?

        payouts_response.map do |payout|
          payout_profile = Spree::PayoutProfiles::PaywayV2.where(bank_account_number: payout['acc']).first_or_create! do |profile|
            profile.name = payout['acc_name']&.strip
          end

          payout_profile_payment = Spree::PayoutProfilePayment.where(payout_profile: payout_profile, payment: @payment).first_or_initialize
          payout_profile_payment.amount = payout['amt'].to_f
          payout_profile_payment
        end
      end

      def checker_hmac
        data = "#{req_time}#{merchant_id}#{transaction_id}"
        hash = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha512'), api_key, data))

        # somehow php counter part are not able to decode if the \n present.
        hash.delete("\n")
      end

      def check_transaction_url
        "#{host}#{ENV['PAYWAY_CHECK_TRANSACTION_PATH']}"
      end
    end
  end
end
