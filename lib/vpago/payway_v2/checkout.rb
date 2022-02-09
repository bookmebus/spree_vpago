module Vpago
  module PaywayV2
    class Checkout < Base
      def gateway_params
        result = {
          req_time: req_time,
          merchant_id: merchant_id,
          tran_id: transaction_id,
          amount: amount,
          firstname: first_name,
          lastname: last_name,
          email: email,
          phone: phone,
          payment_option: payment_option,
          return_url: return_url,
          continue_success_url: continue_success_url,
          return_params: return_params,
          hash: hash_hmac
        }

        result
      end

      def checkout_url
        "#{host}#{ENV['PAYWAY_CHECKOUT_PATH']}"
      end
    end
  end
end
