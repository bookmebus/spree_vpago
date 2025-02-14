module Vpago
  module VpagoPaymentsHelper
    def user_informer
      'firebase'
    end

    # eg. forms/spree/gateway/payway_v2
    def render_form
      render partial: "spree/vpago_payments/forms/#{@payment.payment_method.class.to_s.underscore}"
    end
  end
end
