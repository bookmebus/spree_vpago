module Vpago
  module TrueMoney
    class Checkout < Base
      def generate_payment_urls(platform)
        redirection_type = platform == 'web' ? 'web_redirect' : 'mobileapp'

        request_body = {
          payment_info: payload.to_json,
          redirectionType: redirection_type,
          merchantDeepLink: @payment.processing_deeplink_url,
          merchantAndroidPackageName: android_package_name,
          refererLink: @payment.processing_url
        }

        response = Faraday.post(generate_payment_url) do |req|
          req.headers = default_headers
          req.body = request_body.to_json
        end

        body = parse_json(response.body)
        platform == 'web' ? body['data']['webview'] : body['data']['deeplink']
      rescue Faraday::Error, JSON::ParserError, NoMethodError => e
        Rails.logger.error("Failed to generate payment URL: #{e.class} - #{e.message}")
        raise
      end
    end
  end
end
