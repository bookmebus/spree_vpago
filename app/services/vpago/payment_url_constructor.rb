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

    def query
      { payment_number: payment.number, order_number: order.number, order_jwt_token: order_jwt_token }.to_query
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
