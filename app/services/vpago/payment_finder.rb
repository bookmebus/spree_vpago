module Vpago
  class PaymentFinder
    attr_reader :params_hash

    def initialize(params_hash)
      @params_hash = params_hash
    end

    def find_and_verify
      find_and_verify!
    rescue StandardError, ActiveRecord::RecordNotFound => e
      Rails.logger.error("PaymentJwtVerifier#find_and_verify error: #{e.class} - #{e.message}")
      nil
    end

    def find_and_verify!
      order = Spree::Order.find_by!(number: params_hash[:order_number])
      verify_jwt!(order)

      Spree::Payment.find_by!(number: params_hash[:payment_number])
    end

    def verify_jwt!(order)
      JWT.decode(params_hash[:order_jwt_token], order.token, 'HS256')
    end
  end
end
