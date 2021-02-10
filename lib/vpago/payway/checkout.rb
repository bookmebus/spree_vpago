module Vpago
  module Payway
    class Checkout < Base

      def gateway_params
        result = {
          tran_id: transaction_id,
          amount: amount,
          hash: hash_hmac,
          firstname: first_name,
          lastname: last_name,
          email: email,
          payment_option: payment_option,
          return_url: return_url,
          continue_success_url: continue_success_url,
          return_params: return_params
        }
    
        result[:phone_country_code] = phone_country_code
        result[:phone] = phone
        result
      end
      
    end
  end
end