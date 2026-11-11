module Spree
  module V2
    module Storefront
      class PaymentRedirectSerializer < BaseSerializer
        set_type :payment_redirect

        attributes :id, :amount, :response_code, :number, :state,
                   :payment_method_id, :payment_method_type, :payment_method_name, 
                   :redirect_options, :gateway_params, :action_url
      end
    end
  end
end
