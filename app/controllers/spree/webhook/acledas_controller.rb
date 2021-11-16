module Spree
  module Webhook
    class AcledasController < BaseController
      def success
        
      end

      def error
        payment_source = Spree::VpagoPaymentSource.find_by(transaction_id: params[:_paymenttokenid])
        payment = payment_source.payment
        order = payment.order

        if order.paid?
          flash[:order_completed] = "1" # required by order_just_completed for purchase tracking
        end

        if params[:app_checkout] == 'yes'
          redirect_to order.paid? || payment.pending? ? success_payway_results_path : failed_payway_results_path
        else
          redirect_to order.paid? || payment.pending? ? order_path(order) : checkout_state_path(:payment)
        end
      end
    end
  end
end
