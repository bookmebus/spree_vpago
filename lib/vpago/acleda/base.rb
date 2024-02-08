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
        preferred_success_url = @payment.payment_method.preferred_success_url
        return nil if preferred_success_url.blank?

        query_string = {
          app_checkout: app_checkout,
          order_number: order_number
        }.to_query

        "#{preferred_success_url}?#{query_string}"
      end

      def error_url
        preferred_error_url = @payment.payment_method.preferred_error_url
        return nil if preferred_error_url.blank?

        query_string = {
          app_checkout: app_checkout,
          order_number: order_number
        }.to_query

        "#{preferred_error_url}?#{query_string}"
      end

      def other_url
        preferred_other_url = @payment.payment_method.preferred_other_url
        return nil if preferred_other_url.blank?

        query_string = {
          app_checkout: app_checkout,
          order_number: order_number
        }.to_query

        "#{preferred_other_url}?#{query_string}"
      end

      def acleda_company_name
        @payment.payment_method.preferences[:acleda_company_name]
      end

      def acleda_payment_card
        @payment.payment_method.preferences[:acleda_payment_card]
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
        "#{host}/#{merchant_name}/paymentPage.jsp"
      end
    end
  end
end
