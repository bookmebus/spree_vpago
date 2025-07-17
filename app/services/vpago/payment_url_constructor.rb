require 'google/cloud/firestore'

module Vpago
  class PaymentUrlConstructor
    attr_accessor :payment, :order

    def initialize(payment)
      @payment = payment
      @order = payment.order
    end

    def checkout_url = "#{base_url}/vpago_payments/checkout?#{query}"
    def processing_url = "#{base_url}/vpago_payments/processing?#{query}"
    def success_url = "#{base_url}/vpago_payments/success?#{query}"
    def process_payment_url = "#{base_url}/vpago_payments/process_payment?#{query}"

    def processing_app_url = "#{@payment.payment_method.preferred_merchant_scheme}/vpago_payments/processing?#{query}"

    def query
      params = {
        payment_number: payment.number,
        order_number: order.number,
        order_jwt_token: order_jwt_token
      }

      params[:offsite_payment] = true if payment.payment_method.type_true_money?

      params.to_query
    end

    def payment_url
      "#{base_url}/book/payment?number=#{@payment.order.number}&tk=#{@payment.order.token}"
    end

    private

    def base_url
      order.payment_host
    end

    def order_jwt_token
      payload = { order_number: order.number, order_id: order.id }
      JWT.encode(payload, order.token, 'HS256')
    end
  end
end
