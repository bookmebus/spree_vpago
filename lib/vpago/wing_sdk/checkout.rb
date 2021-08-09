module Vpago
  module WingSdk
    class Checkout < Base
      def gateway_params
        {
          remark: payment_number,
          ask_remember: 0,
          sandbox: sandbox,
          bill_till_rbtn: 0,
          amount: amount_with_fee,
          bill_till_number: biller_code,
          username: username,
          rest_api_key: rest_api_key,
          return_url: return_url
        }
      end
    end
  end
end
