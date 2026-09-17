require 'faraday'

module Vpago
  module PaywayV2
    class TransactionCreator < Checkout
      def call
        @response = submit_transaction
      end

      def json_response
        @json_response ||= JSON.parse(@response.body)
      rescue JSON::ParserError
        {}
      end

      private

      def submit_transaction
        conn = Faraday::Connection.new do |faraday|
          faraday.request :url_encoded
          faraday.options.open_timeout = Vpago::HttpTimeouts::OPEN_TIMEOUT
          faraday.options.timeout = Vpago::HttpTimeouts::TIMEOUT
        end

        conn.post(checkout_url, gateway_params)
      end
    end
  end
end
