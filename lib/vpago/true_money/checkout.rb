module Vpago
  module TrueMoney
    class Checkout < Base
      def generate_payment_urls
        request_body = {
          payment_info: payload.to_json,
          redirectionType: redirection_type
        }

        if redirection_type == 'mobileapp'
          request_body[:merchantDeepLink] = @payment.processing_app_url
          request_body[:merchantAndroidPackageName] = merchant_android_package_name
        else
          request_body[:refererLink] = @payment.processing_url
        end

        response = Faraday.post(generate_payment_url) do |req|
          req.headers = default_headers
          req.body = request_body.to_json
        end

        body = parse_json(response.body)

        raise "Generate Payment Error: #{response.status} - #{body['message'] || response.body}" unless response.success? && body.dig('status', 'code') == '000001'

        {
          webview: body['data']['webview'],
          deeplink: body['data']['deeplink']
        }
      end
    end
  end
end
