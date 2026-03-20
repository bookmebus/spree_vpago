module Vpago
  module PaywayV2
    class Base
      def initialize(payment, options = {})
        @options = options
        @payment = payment
        @disable_return_deeplink = options[:disable_return_deeplink] || false
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

      # optional
      def email
        @payment.order.email.presence || ENV.fetch('DEFAULT_EMAIL_FOR_PAYMENT', nil)
      end

      def first_name
        @payment.order.billing_address&.first_name&.strip
      end

      def last_name
        @payment.order.billing_address&.last_name&.strip
      end

      def return_url
        uri = URI.parse(@payment.process_payment_url)
        uri.query = nil

        Base64.encode64(uri.to_s).delete("\n")
      end

      def continue_success_url
        @payment.processing_url
      end

      # null, hosted_view, checkout, qr
      def view_type
        'hosted_view'
      end

      def payment_option
        @payment.payment_method.preferences[:payment_option]
      end

      # optional
      def phone
        @payment.order.billing_address&.phone
      end

      def api_key
        @payment.payment_method.preferences[:api_key]
      end

      def return_params
        uri = URI.parse(@payment.process_payment_url)
        query_params = Rack::Utils.parse_nested_query(uri.query)
        query_params.to_json
      end

      def payout
        @payout ||= begin
          payouts = Vpago::PaywayV2::PayoutsParamsConstructor.new(@payment).call
          payouts.empty? ? nil : Base64.strict_encode64(payouts.to_json)
        end
      end

      def return_deeplink_url
        # In Telegram, Facebook, and Messenger webviews, there is no reliable way for
        # ABA to detect the originating app. Using `continue_success_url` may open the
        # default browser instead of the intended app (e.g., Telegram or Facebook),
        # resulting in a poor user experience.
        #
        # To prevent ABA from returning to the wrong app, we allow returning nil by
        # setting `disable_return_deeplink: true`:
        # - Android: ABA app automatically returns to the previous app (expected behavior)
        # - iOS: no automatic redirect occurs, but users can tap "Back to <App>" at the top of ABA
        return nil if @disable_return_deeplink

        app_scheme = @payment.payment_method.preferences[:app_scheme]

        if app_scheme.present?
          uri = URI.parse(continue_success_url)
          uri.scheme = app_scheme
          uri.to_s
        else
          continue_success_url
        end
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
        result = "#{req_time}#{merchant_id}#{transaction_id}#{amount}#{first_name}#{last_name}"

        result += email if email.present?
        result += phone if phone.present?
        result += type if type.present?
        result += payment_option if payment_option.present?
        result += return_url if return_url.present?
        result += continue_success_url if continue_success_url.present?
        result += return_deeplink if return_deeplink.present?
        result += return_params if return_params.present?
        result += payout if payout.present?
        result += skip_success_page.to_s if skip_success_page.present?

        log_hash_data = "Hash data: #{result}"
        Rails.logger.info(log_hash_data)

        result
      end

      def order_jwt_token
        payload = { order_number: @payment.order.number, order_id: @payment.order.id }
        JWT.encode(payload, @payment.order.token, 'HS256')
      end

      def skip_success_page
        1
      end
    end
  end
end
