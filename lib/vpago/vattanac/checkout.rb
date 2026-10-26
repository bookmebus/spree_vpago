module Vpago
  module Vattanac
    class Checkout < Base
      def payload
        {
          transactionId: payment_number,
          requestId: "req-#{SecureRandom.hex(8)}",
          paymentType: payment_type,
          amount: amount,
          currency: currency,
          merchantId: merchant_id,
          returnUrl: @payment.processing_url
        }
      end

      def create
        response_data = post(generate_payment_url, payload)['data']
        {
          web_url: response_data['webPaymentUrl'],
          deeplink_url: response_data['mobileDeepLink'],
          expires_at: response_data['expiredIn'],
          generated_at: response_data['generatedAt']
        }
      end
    end
  end
end

