module Vpago
  module TrueMoney
    class RefundIssuer < Base
      def call
        @response = Faraday.post(refund_url, payload.to_json, default_headers)
      end

      def success?
        parsed_response.dig('status', 'code') == '000001'
      end

      def payload
        { external_ref_id: external_ref_id }
      end

      def parsed_response
        @parsed_response ||= parse_json(@response.body)
      end
    end
  end
end
