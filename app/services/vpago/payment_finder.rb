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
      if vattanac_mini_app_callback?
        payload = Vpago::VattanacMiniAppDataHandler.new.decrypt_data(@params_hash[:data])
        payment = Spree::Payment.find_by!(number: payload['paymentId'])
        payment.update(transaction_response: payload)
        payment
      elsif acleda_v2_callback?
        # ACLEDA V2's static portal callback echoes back _transactionid, which is
        # the payment number we sent as transactionID/txid at openSessionV2.
        Spree::Payment.find_by!(number: params_hash[:_transactionid])
      else
        order = Spree::Order.find_by!(number: params_hash[:order_number])
        verify_jwt!(order)

        Spree::Payment.find_by!(number: params_hash[:payment_number])
      end
    end

    def verify_jwt!(order)
      JWT.decode(params_hash[:order_jwt_token], order.token, 'HS256')
    end

    def vattanac_mini_app_callback?
      params_hash[:data].present?
    end

    def acleda_v2_callback?
      params_hash[:_paymenttokenid].present?
    end
  end
end
