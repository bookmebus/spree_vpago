module Vpago
  module TrueMoney
    class Checkout < Base
      def generate_payment_urls
        response = Faraday.post(generate_payment_url) do |req|
          req.headers = default_headers
          req.body = {
            payment_info: payload.to_json,
            redirectionType: 'mobileapp',
            merchantDeepLink: @payment.processing_app_url,
            merchantAndroidPackageName: merchant_android_package_name
          }.to_json
        end

        body = parse_json(response.body)

        raise "Generate Payment Error: #{response.status} - #{body['message'] || response.body}" unless response.success? && body['status']['code'] == '000001'

        {
          webview: body['data']['webview'],
          deeplink: body['data']['deeplink']
        }
      end
    end
  end
end
