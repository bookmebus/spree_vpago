module Vpago
  module Payway
    class Checkout

      def initialize(payment)
        @payment = payment
      end

      def amount
        "%.2f" % ( @payment.amount + transaction_fee )
      end

      def transaction_fee_fix
        @payment.payment_method.preferences[:transaction_fee_fix].to_f
      end
    
      def transaction_fee_percentage
        @payment.payment_method.preferences[:transaction_fee_percentage].to_f
      end
    
      def transaction_fee
        transaction_fee_fix + (@payment.amount * transaction_fee_percentage ) / 100
      end

      def merchant_id
        @payment.payment_method.preferences[:merchant_id]
      end

      def transaction_id
        @payment.number
      end

      def email
        ENV['SUPPORT_EMAIL']
      end

      def return_url
        @payment.payment_method.preferences[:return_url]
      end

      def continue_success_url
        @payment.payment_method.preferences[:continue_success_url]
      end

      def payment_option
        card_option = @payment.payment_method.preferences[:payment_option]
        ['abapay', 'cards'].index(card_option) == nil ? 'abapay' : card_option
      end

      def phone_country_code
        ""
      end

      def phone
        ""
      end

      def api_key
        @payment.payment_method.preferences[:api_key]
      end

      def hash_hmac
        data = "#{merchant_id}#{transaction_id}#{amount}"
        hash = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha512'), api_key, data))
        hash.delete("\n")
      end

      def gateway_params
        result = {
          tran_id: transaction_id,
          amount: amount,
          hash: hash_hmac,
          firstname: "",
          lastname: "",
          email: email,
          payment_option: payment_option,
          return_url: Base64.encode64(return_url),
          continue_success_url: continue_success_url,
        }
    
        result[:phone_country_code] = phone_country_code
        result[:phone] = phone
      end
      
    end
  end
end