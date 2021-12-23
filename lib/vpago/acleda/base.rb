module Vpago
  module Acleda
    class Base
      include Vpago::PaymentAmountCalculator

      def initialize(payment, options={})
        @options = options
        @payment = payment
      end

      def payment_number
        @payment.number
      end

      def app_checkout
        is_app_checkout? ? '1' : '0'
      end

      def is_app_checkout?
        return false if @options[:app_checkout].blank?

        @options[:app_checkout]
      end

      def host
        @payment.payment_method.preferences[:host]
      end

      def success_url
        "#{@payment.payment_method.preferences[:success_url]}?app_checkout=#{app_checkout}"
      end

      def error_url
        "#{@payment.payment_method.preferences[:error_url]}?app_checkout=#{app_checkout}"
      end

      def login_id
        @payment.payment_method.preferences[:login_id]
      end

      def password
        @payment.payment_method.preferences[:password]
      end

      def merchant_id
        @payment.payment_method.preferences[:merchant_id]
      end

      def merchant_name
        @payment.payment_method.preferences[:merchant_name]
      end

      def signature
        @payment.payment_method.preferences[:signature]
      end

      def expiry_time
        @payment.payment_method.preferences[:payment_expiry_time_in_mn]
      end
      
      def purchase_date
        @payment.created_at.strftime("%d-%m-%Y")
      end

      def order_number
        @payment.order.number
      end

      def action_url
        "#{host}/VETDIGITAL/paymentPage.jsp"
      end
    end
  end
end
