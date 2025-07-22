module Vpago
  module TrueMoney
    class Base
      TOKEN_HEADERS     = { 'Content-Type' => 'application/x-www-form-urlencoded' }.freeze
      CONTENT_TYPE_JSON = 'application/json'.freeze
      DEFAULT_ALGORITHM = 'rsa-sha256'.freeze
      DEFAULT_KEY_VERSION = 1

      def initialize(payment, options = {})
        @payment = payment
        @options = options
      end

      def client_id
        payment_method.preferred_client_id
      end

      def client_secret
        payment_method.preferred_client_secret
      end

      def private_key
        payment_method.preferred_private_key
      end

      def redirect_type
        payment_method.preferred_redirect_type
      end

      def external_ref_id
        @payment.number
      end

      def service_type = '01'
      def currency     = 'USD'
      def user_type    = 'CUSTOMER'

      def amount
        @payment.amount
      end

      def timestamp
        @timestamp ||= Time.now.to_i
      end

      def access_token
        @access_token ||= fetch_access_token
      end

      def payload
        {
          service_type: service_type,
          external_ref_id: external_ref_id,
          amount: amount,
          currency: currency,
          user_type: user_type
        }
      end

      def signature
        Vpago::RsaHandler
          .new(private_key: private_key)
          .generate_signature(signature_input)
      end

      def default_headers
        {
          'Client-Id' => client_id,
          'Authorization' => "Bearer #{access_token}",
          'Signature' => "algorithm=#{algorithm};keyVersion=#{key_version};signature=#{signature}",
          'Timestamp' => timestamp.to_s,
          'Content-Type' => CONTENT_TYPE_JSON
        }
      end

      def check_transaction_url
        "#{payment_method.preferred_check_transaction_url}/#{external_ref_id}"
      end

      def refund_url
        payment_method.preferred_refund_url
      end

      def generate_payment_url
        payment_method.preferred_generate_payment_url
      end

      def access_token_url
        payment_method.preferred_access_token_url
      end

      def android_package_name
        payment_method.preferred_android_package_name
      end

      def parse_json(body)
        JSON.parse(body)
      rescue JSON::ParserError
        {}
      end

      def fetch_access_token
        response = Faraday.post(
          access_token_url,
          URI.encode_www_form(
            grant_type: 'client_credentials',
            client_id: client_id,
            client_secret: client_secret
          ),
          TOKEN_HEADERS
        )

        raise "Access Token Error: #{response.status} - #{response.body}" unless response.success?

        JSON.parse(response.body).fetch('access_token')
      end

      def return_url_scheme
        payment_method.preferred_return_url_scheme
      end

      def return_deeplink
        "#{return_url_scheme}/vpago_payments/processing?payment_number=#{external_ref_id}&order_number=#{order.number}&order_jwt_token=#{order_jwt_token}"
      end

      def order_jwt_token
        @order_jwt_token ||= JWT.encode(jwt_payload, order.token, 'HS256')
      end

      def order
        @payment.order
      end

      def jwt_payload
        { order_number: order.number, order_id: order.id }
      end

      def payment_method
        @payment.payment_method
      end

      def algorithm
        DEFAULT_ALGORITHM
      end

      def key_version
        DEFAULT_KEY_VERSION
      end

      def signature_input
        "#{timestamp}#{payload.to_json}"
      end
    end
  end
end
