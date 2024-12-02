module Vpago
  module PaywayV2
    class Base
      def initialize(payment, options = {})
        @options = options
        @payment = payment
      end

      def req_time
        @payment.created_at.strftime('%Y%m%d%H%M%S')
      end

      def type
        @payment.payment_method.enable_pre_auth ? 'pre-auth' : 'purchase'
      end

      def host
        @payment.payment_method.preferences[:host]
      end

      def public_key
        @payment.payment_method.preferences[:public_key]
      end

      def amount
        format('%.2f', (@payment.amount + transaction_fee))
      end

      def transaction_fee_fix
        @payment.payment_method.preferences[:transaction_fee_fix].to_f
      end

      def transaction_fee_percentage
        @payment.payment_method.preferences[:transaction_fee_percentage].to_f
      end

      def transaction_fee
        transaction_fee_fix + ((@payment.amount * transaction_fee_percentage) / 100)
      end

      def merchant_id
        @payment.payment_method.preferences[:merchant_id]
      end

      def transaction_id
        @payment.number
      end

      def email
        @payment.order.email.presence || ENV.fetch('DEFAULT_EMAIL_FOR_PAYMENT', nil)
      end

      def first_name
        @payment.order.billing_address.first_name.strip
      end

      def last_name
        @payment.order.billing_address.last_name.strip
      end

      def return_url
        preferred_return_url = ENV.fetch('PAYWAY_RETURN_CALLBACK_URL', nil)
        return nil if preferred_return_url.blank?

        Base64.encode64(preferred_return_url).delete("\n")
      end

      def app_checkout
        is_app_checkout? ? 'yes' : 'no'
      end

      def is_app_checkout?
        return false if @options[:app_checkout].blank?

        @options[:app_checkout]
      end

      def continue_success_url
        preferred_continue_url = ENV.fetch('PAYWAY_CONTINUE_SUCCESS_CALLBACK_URL', nil)
        return nil if preferred_continue_url.blank?

        query_string = {
          tran_id: transaction_id,
          app_checkout: app_checkout,
          order_number: @payment.order.number,
          order_channel: @payment.order.channel
        }.to_query

        preferred_continue_url.index('?').nil? ? "#{preferred_continue_url}?#{query_string}" : "#{preferred_continue_url}&#{query_string}"
      end

      # null, hosted_view, checkout, qr
      def view_type
        is_app_checkout? ? 'hosted_view' : nil
      end

      def payment_option
        card_option = @payment.payment_method.preferences[:payment_option]

        return 'abapay_deeplink' if is_app_checkout? && card_option == 'abapay'
        return 'abapay_khqr' if !is_app_checkout? && card_option == 'abapay_khqr_deeplink'

        Vpago::Payway::CARD_TYPES.index(card_option).nil? ? Vpago::Payway::CARD_TYPE_ABAPAY : card_option
      end

      def phone_country_code
        '+855'
      end

      def phone
        @payment.order.billing_address.phone
      end

      def api_key
        @payment.payment_method.preferences[:api_key]
      end

      def return_params
        { tran_id: transaction_id }.to_json
      end

      def payout
        @payout ||= begin
          payouts = Vpago::PaywayV2::PayoutsParamsConstructor.new(@payment).call
          payouts.empty? ? nil : Base64.strict_encode64(payouts.to_json)
        end
      end

      def return_deeplink_url
        scheme = @payment.payment_method.preferences[:deeplink_scheme]

        # let client pass override return deeplink eg. from tg://t.me
        return @options[:override_return_deeplink_url] if @options[:override_return_deeplink_url].present?
        return nil unless continue_success_url.present?

        uri = URI.parse(continue_success_url)
        uri.scheme = scheme if is_app_checkout? && scheme.present?
        uri.to_s
      end

      def return_deeplink
        return nil unless return_deeplink_url.present?

        Base64.strict_encode64({ android_scheme: return_deeplink_url, ios_scheme: return_deeplink_url }.to_json)
      end

      def hash_hmac
        hash = Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha512'), api_key, hash_data))

        log_hash_data = "Hash hmac: #{hash}"
        Rails.logger.info(log_hash_data)

        hash
      end

      def hash_data
        result = "#{req_time}#{merchant_id}#{transaction_id}#{amount}#{first_name}#{last_name}#{email}#{phone}"

        result += type if type.present?
        result += payment_option if payment_option.present?
        result += return_url if return_url.present?
        result += continue_success_url if continue_success_url.present?
        result += return_deeplink if return_deeplink.present?
        result += return_params if return_params.present?
        result += payout if payout.present?

        log_hash_data = "Hash data: #{result}"
        Rails.logger.info(log_hash_data)

        result
      end
    end
  end
end
