require 'faraday'

module Vpago
  module Vattanac
    class Base
      CONTENT_TYPE_JSON = 'application/json'.freeze

      def initialize(payment)
        @payment = payment
      end

      def username
        payment_method.preferred_username
      end

      def password
        payment_method.preferred_password
      end

      def access_token_url
        payment_method.preferred_access_token_url
      end

      def generate_payment_url
        payment_method.preferred_generate_payment_url
      end

      def check_transaction_url
        payment_method.preferred_check_transaction_url
      end

      def access_token
        @access_token ||= fetch_access_token
      end

      def payment_method
        @payment.payment_method
      end

      def payment_number
        @payment.number
      end

      def payment_type
        payment_method.preferred_payment_type
      end

      def merchant_id
        payment_method.preferred_merchant_id
      end

      def amount
        @payment.amount
      end

      def currency
        'USD'
      end

      def default_headers
        { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => CONTENT_TYPE_JSON }
      end

      def parse_json(body)
        JSON.parse(body)
      rescue JSON::ParserError
        {}
      end

      private

      def fetch_access_token
        response = Faraday.new(request: { open_timeout: Vpago::HttpTimeouts::OPEN_TIMEOUT, timeout: Vpago::HttpTimeouts::TIMEOUT })
                          .post(access_token_url, { username: username, password: password }.to_json, { 'Content-Type' => CONTENT_TYPE_JSON })

        raise "Access Token Error: #{response.status} - #{response.body}" unless response.success?

        parse_json(response.body).dig('data', 'accessToken') || raise('Missing accessToken in response')
      end

      def post(url, body)
        response = Faraday.new(request: { open_timeout: Vpago::HttpTimeouts::OPEN_TIMEOUT, timeout: Vpago::HttpTimeouts::TIMEOUT }).post(url, body.to_json, default_headers)
        parse_json(response.body)
      end
    end
  end
end
