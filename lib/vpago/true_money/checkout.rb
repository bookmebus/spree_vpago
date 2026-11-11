module Vpago
  module TrueMoney
    class Checkout < Base
      def generate_payment_urls(_platform)
        request_body = {
          payment_info: payload.to_json,
          redirectionType: redirect_type,
          merchantDeepLink: return_deeplink,
          merchantAndroidPackageName: android_package_name,
          refererLink: @payment.processing_url
        }

        response = Faraday.post(generate_payment_url) do |req|
          req.headers = default_headers
          req.body = request_body.to_json
        end

        body = parse_json(response.body)

        {
          webview: body['data']['webview'],
          deeplink: body['data']['deeplink']
        }
      rescue Faraday::Error, JSON::ParserError, NoMethodError => e
        Rails.logger.error("Failed to generate payment URL: #{e.class} - #{e.message}")
        raise
      end
    end
  end
end
