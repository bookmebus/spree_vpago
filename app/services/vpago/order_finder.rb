module Vpago
  # Order-based counterpart to Vpago::PaymentFinder, for flows that have no Spree::Payment to key
  # off of (order_total_after_store_credit == 0: store credit covering the order in full, cash-on
  # with nothing left to pay after store credit, or a free event -- see Vpago::OrderProcessor).
  class OrderFinder
    attr_reader :params_hash

    def initialize(params_hash)
      @params_hash = params_hash
    end

    def find_and_verify
      find_and_verify!
    rescue StandardError, ActiveRecord::RecordNotFound => e
      Rails.logger.error("Vpago::OrderFinder#find_and_verify error: #{e.class} - #{e.message}")
      nil
    end

    def find_and_verify!
      order = Spree::Order.find_by!(number: params_hash[:order_number])
      verify_jwt!(order)
      order
    end

    def verify_jwt!(order)
      JWT.decode(params_hash[:order_jwt_token], order.token, 'HS256')
    end
  end
end
