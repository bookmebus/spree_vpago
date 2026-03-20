module Vpago
  module PaywayV2
    class Checkout < Base
      def gateway_params
        result = {
          req_time: req_time,
          merchant_id: merchant_id,
          tran_id: transaction_id,
          amount: amount,
          type: type,
          firstname: first_name,
          lastname: last_name,
          payment_option: payment_option,
          return_url: return_url,
          continue_success_url: continue_success_url,
          return_params: return_params,
          skip_success_page: skip_success_page,
          hash: hash_hmac
        }

        result[:email] = email unless email.nil?
        result[:phone] = phone unless phone.nil?
        result[:return_deeplink] = return_deeplink unless return_deeplink.nil?
        result[:view_type] = view_type unless view_type.nil?
        result[:payout] = payout unless payout.nil?
        result
      end

      def checkout_url
        "#{host}/api/payment-gateway/v1/payments/purchase"
      end

      alias action_url checkout_url
    end
  end
end
