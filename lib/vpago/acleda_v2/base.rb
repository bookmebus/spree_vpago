module Vpago
  module AcledaV2
    class Base
      CONTENT_TYPE_JSON = 'application/json'.freeze
      # ACLEDA requires purchaseDesc to be <= 16 chars, English only.
      PURCHASE_DESC = 'Purchase goods'.freeze

      def initialize(payment, options = {})
        @options = options
        @payment = payment
      end

      def payment_method
        @payment.payment_method
      end

      def payment_number
        @payment.number
      end

      def amount
        format('%.2f', @payment.amount)
      end

      # txid <= 16 chars; payment.number fits.
      alias transaction_id payment_number

      def order_number
        @payment.order.number
      end

      def merchant_name
        payment_method.preferences[:merchant_name]
      end

      def merchant_id
        payment_method.preferences[:merchant_id]
      end

      def login_id
        payment_method.preferences[:login_id]
      end

      def password
        payment_method.preferences[:password]
      end

      def secret
        payment_method.preferences[:secret]
      end

      # Dynamically mirrors the shopper's remaining seat/inventory hold time so the bank's
      # QR/session doesn't outlive the hold. Falls back to the admin-configured preference
      # when the order has no hold (e.g. non-inventory items) or the hold has already lapsed.
      def expiry_time
        @expiry_time ||= (remaining_hold_minutes || payment_method.preferences[:payment_expiry_time_in_mn]).to_s
      end

      def purchase_date
        @payment.created_at.utc.strftime('%Y-%m-%d')
      end

      def purchase_currency
        @payment.order.currency
      end

      def xpay_service_base_url
        strip_whitespace(payment_method.preferences[:xpay_service_base_url])
      end

      def open_session_url
        "#{xpay_service_base_url}/openSessionV2"
      end

      def get_txn_status_url # rubocop:disable Naming/AccessorMethodName
        "#{xpay_service_base_url}/getTxnStatus"
      end

      # KHQR/Card secure web redirect target
      def action_url
        strip_whitespace(payment_method.preferences[:payment_page_url])
      end

      # successUrlToReturn / errorUrl. The bank appends its own query string
      # (_paymenttokenid, _resultCode, ...) when it redirects back.
      def continue_success_url
        @payment.processing_url
      end

      def callback_url
        return continue_success_url unless deeplink? && app_scheme.present?

        uri = URI.parse(continue_success_url)
        uri.scheme = app_scheme
        uri.to_s
      end

      def app_scheme
        payment_method.preferences[:app_scheme]
      end

      # android | ios (defaults to android when not supplied by the caller)
      def opr_device
        @options[:opr_device].presence || 'android'
      end

      def platform
        @options[:platform]
      end

      def deeplink?
        payment_method.deeplink? && platform == 'app'
      end

      # --- HMAC-SHA512 (uppercase hex) signing ---
      # openSessionV2 message: merchantID + loginId + password + txid
      def open_session_hash
        hmac512("#{merchant_id}#{login_id}#{password}#{payment_number}")
      end

      # getTxnStatus message: merchantId + loginId + password + paymentTokenid
      def txn_status_hash(token)
        hmac512("#{merchant_id}#{login_id}#{password}#{token}")
      end

      def hmac512(message)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha512'), secret, message).upcase
      end

      def parse_json(body)
        JSON.parse(body)
      rescue JSON::ParserError
        {}
      end

      private

      # Minutes left on the order's seat/inventory hold, rounded up so we never quote the
      # bank less time than is actually left. nil when the order has no hold, the hold has
      # already lapsed, or hold_expires_at isn't defined (spree_cm_commissioner not loaded).
      def remaining_hold_minutes
        return nil unless @payment.order.respond_to?(:hold_expires_at)

        hold_expires_at = @payment.order.hold_expires_at
        return nil if hold_expires_at.blank?

        minutes = ((hold_expires_at - Time.current) / 60.0).ceil
        minutes if minutes.positive?
      end

      def strip_whitespace(value)
        value.to_s.gsub(/\s+/, '')
      end
    end
  end
end
