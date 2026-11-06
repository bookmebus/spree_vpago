module Vpago
  class OrderUrlConstructor
    attr_accessor :order

    def initialize(order)
      @order = order
    end

    def processing_url = "#{base_url}/vpago_orders/processing?#{query}"
    def success_url = "#{base_url}/vpago_orders/success?#{query}"

    def process_order_url = "#{base_url}/vpago_orders/process_order?#{query}"

    def query
      { order_number: order.number, order_jwt_token: order_jwt_token }.to_query
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
