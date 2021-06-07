module Spree
  module V2
    module Storefront
      class PaymentRedirectSerializer < BaseSerializer
        set_type :payment_redirect

        attributes :id, :amount, :response_code, :number, :state,
                   :payment_method_id, :payment_method_name, :redirect_options
      end
    end
  end
end
