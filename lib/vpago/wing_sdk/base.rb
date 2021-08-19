module Vpago
  module WingSdk
    class Base
      include Vpago::PaymentAmountCalculator

      def initialize(payment, options={})
        @options = options
        @payment = payment
      end

      def payment_number
        @payment.number
      end

      def sandbox
        @payment.payment_method.preferences[:sandbox] ? '1' : '0'
      end

      def biller_code
        @payment.payment_method.preferences[:biller_code]
      end

      def username
        @payment.payment_method.preferences[:username]
      end

      def rest_api_key
        @payment.payment_method.preferences[:rest_api_key]
      end

      def return_url
        "#{ENV['DEFAULT_URL_HOST']}/webhook/wings/#{payment_number}/return?app_checkout=#{app_checkout}"
      end

      def app_checkout
        is_app_checkout? ? 'yes' : 'no'
      end

      def is_app_checkout?
        return false if @options[:app_checkout].blank?

        @options[:app_checkout]
      end

      def host
        @payment.payment_method.preferences[:host]
      end

      def action_url
        host
      end
    end
  end
end
