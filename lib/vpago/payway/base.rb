module Vpago
  module Payway
    class Base
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
        @payment.order.email.presence || ENV['SUPPORT_EMAIL']
      end

      def first_name
        @payment.order.billing_address.first_name
      end

      def last_name
        @payment.order.billing_address.last_name
      end

      def return_url
        preferred_return_url = @payment.payment_method.preferences[:return_url]
        return nil if preferred_return_url.blank?
        
        Base64.encode64(preferred_return_url)
      end

      def continue_success_url
        preferred_continue_url = @payment.payment_method.preferences[:continue_success_url]
        return nil if preferred_continue_url.blank?

        query_string = "tran_id=#{transaction_id}"
        preferred_continue_url.index("?") == nil ? "#{preferred_continue_url}?#{query_string}" : "#{preferred_continue_url}&#{query_string}"
      end

      def payment_option
        card_option = @payment.payment_method.preferences[:payment_option]
        Vpago::Payway::CARD_TYPES.index(card_option) == nil ?  Vpago::Payway::CARD_TYPE_ABAPAY : card_option
      end

      def phone_country_code
        "+855"
      end

      def phone
        @payment.order.billing_address.phone
      end

      def api_key
        @payment.payment_method.preferences[:api_key]
      end

      def return_params
        {tran_id: transaction_id}.to_json
      end

      def hash_hmac
        data = "#{merchant_id}#{transaction_id}#{amount}"
        hash = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha512'), api_key, data))

        # somehow php counter part are not able to decode if the \n present.
        hash.delete("\n")
      end

      def endpoint
        @payment.payment_method.preferences[:endpoint]
      end
    end
  end
end