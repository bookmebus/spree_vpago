module Vpago
  module VpagoPaymentsHelper
    def user_informer
      'firebase'
    end

    # eg. forms/spree/gateway/payway_v2
    def render_checkout_form
      render partial: checkout_form_partial_path
    end

    # Not every payment method has (or needs) a checkout-form partial -- store credit, cash-on,
    # and similar methods are processed instantly/manually with no external redirect/QR/webview
    # step. Mirrors the existence-check pattern already used by render_additional_processing_script
    # below, rather than guessing from the payment method's class/namespace (the "Gateway::" in
    # e.g. Spree::Gateway::PaywayV2 is a naming convention only -- none of these classes actually
    # inherit from Spree::Gateway).
    def checkout_form_exists?(payment)
      lookup_context.exists?(checkout_form_partial_path(payment), [], true)
    end

    def checkout_form_partial_path(payment = @payment)
      "spree/vpago_payments/forms/#{payment.payment_method.class.to_s.underscore}"
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
