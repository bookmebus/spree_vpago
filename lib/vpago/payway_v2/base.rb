module Vpago
  module PaywayV2
    class Base
      def initialize(payment, options={})
        @options = options
        @payment = payment
      end

      def req_time
        @payment.created_at.strftime('%Y%m%d%H%M%S')
      end

      def host
        @payment.payment_method.preferences[:host]
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
        @payment.order.email.presence || ENV['DEFAULT_EMAIL_FOR_PAYMENT']
      end

      def first_name
        @payment.order.billing_address.first_name
      end

      def last_name
        @payment.order.billing_address.last_name
      end

      def return_url
        preferred_return_url = ENV['PAYWAY_RETURN_CALLBACK_URL']
        return nil if preferred_return_url.blank?
        
        Base64.encode64(preferred_return_url).delete("\n")
      end

      def app_checkout
        is_app_checkout? ? 'yes' : 'no'
      end

      def is_app_checkout?
        return false if @options[:app_checkout].blank?

        @options[:app_checkout]
      end

      def continue_success_url
        preferred_continue_url = ENV['PAYWAY_CONTINUE_SUCCESS_CALLBACK_URL']
        return nil if preferred_continue_url.blank?

        query_string = "tran_id=#{transaction_id}&app_checkout=#{app_checkout}"
        preferred_continue_url.index("?") == nil ? "#{preferred_continue_url}?#{query_string}" : "#{preferred_continue_url}&#{query_string}"
      end

      def payment_option
        card_option = @payment.payment_method.preferences[:payment_option]

        return 'abapay_deeplink' if is_app_checkout? && card_option == 'abapay'

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
        hash = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha512'), api_key, hash_data))

        # somehow php counter part are not able to decode if the \n present.
        hash.delete("\n")
      end

      def hash_data
        "#{req_time}#{merchant_id}#{transaction_id}#{amount}#{first_name}#{last_name}#{email}#{phone}#{payment_option}#{return_url}#{continue_success_url}#{return_params}"
      end
    end
  end
end
