module Vpago
  module VpagoPaymentsHelper
    def user_informer
      'firebase'
    end

    # eg. forms/spree/gateway/payway_v2
    def render_checkout_form
      render partial: "spree/vpago_payments/forms/#{@payment.payment_method.class.to_s.underscore}"
    end

    def render_transaction_checker
      render partial: 'spree/vpago_payments/transaction_checker'
    end

    # Each payment method may have their own additional processing script,
    # so we will look for the partial based on the payment method class name.
    # 
    # eg. processing_scripts/spree/gateway/payway_v2
    def render_additional_processing_script(payment)
      processing_script_partial_path = "spree/vpago_payments/processing_scripts/#{payment.payment_method.class.to_s.underscore}"
      render partial: processing_script_partial_path if lookup_context.exists?(processing_script_partial_path, [], true)
    end

    def mobile_user_agent?
      request.user_agent.to_s.downcase.match?(/android|iphone|ipad|ipod/)
    end
  end
end
