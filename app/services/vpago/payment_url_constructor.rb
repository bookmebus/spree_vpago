require 'google/cloud/firestore'

module Vpago
  class PaymentUrlConstructor
    attr_accessor :payment, :order

    def initialize(payment)
      @payment = payment
      @order = payment.order
    end

    def checkout_url = "#{base_url}/vpago_payments/checkout?#{query}"
    def web_checkout_url = "#{base_url}/vpago_payments/checkout?#{query}&platform=web"
    def processing_url = "#{base_url}/vpago_payments/processing?#{query}"
    def processing_deeplink_url = "#{@payment.payment_method.preferred_return_url_scheme}book/payment?number=#{order.number}&tk=#{order.token}"
    def success_url = "#{base_url}/vpago_payments/success?#{query}"
    def process_payment_url = "#{base_url}/vpago_payments/process_payment?#{query}"

    def query
      {
        payment_number: payment.number,
        order_number: order.number,
        order_jwt_token: order_jwt_token,
        offsite_payment: offsite_payment? ? true : nil
      }.compact.to_query
    end

    def offsite_payment?
      payment.payment_method.type_true_money?
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
