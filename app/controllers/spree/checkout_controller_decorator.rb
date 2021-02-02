module Spree
  module VpagoGatewayCheckout
    def update
      if payment_params_valid? && vpago_payment_method?
        process_with_vpago_gateway
      else
        super
      end
    end

    private
    def process_with_vpago_gateway
      updated = @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)

      if updated
        payment = @order.payments.last
        payment.process!
        @client_redirect = ::Vpago::Payway::Checkout.new(payment)
       
        render 'spree/checkout/payment/payway_form', layout: false
      else
        render :edit
      end
    end
  end

  module CheckoutControllerDecorator

    def vpago_payment_method?
      payment_method_id_param = params[:order][:payments_attributes].first[:payment_method_id]
      payment_method = PaymentMethod.find(payment_method_id_param)
      payment_method.type == 'Spree::Gateway::Payway'
    end

    def payment_params_valid?
      (params[:state] === 'payment') && params[:order][:payments_attributes].present?
    end
  end

  CheckoutController.prepend(VpagoGatewayCheckout)
  CheckoutController.prepend(CheckoutControllerDecorator)
end

