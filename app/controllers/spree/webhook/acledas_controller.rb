module Spree
  module Webhook
    class AcledasController < BaseController
      before_action :find_payment, only: [:success, :error]

      ## success
      ## {"_arNo"=>"PJ9ETZD4", "_transactionid"=>"PJ9ETZD4", "_paymentresult"=>"SUCCESS", "_paymenttokenid"=>"lVqWKcLHVk6s0rIgk/T8Vdbzsg0=", "_resultCode"=>"0", "controller"=>"spree/webhook/acledas", "action"=>"success"}
      def success
        request_updater = ::Vpago::Acleda::PaymentRequestUpdater.new(@payment)
        request_updater.call

        order = @payment.order
        order = order.reload

        if order.paid? || @payment.pending?
          flash[:order_completed] = "1" if order.paid? # required by order_just_completed for purchase tracking
          redirect_to order_path(order)
        else
          redirect_to checkout_state_path(:payment)
        end
      end

      def error
        order = @payment.order

        if order.paid?
          flash[:order_completed] = "1" # required by order_just_completed for purchase tracking
        end

        if params[:app_checkout] == 'yes'
          redirect_to order.paid? || @payment.pending? ? success_payway_results_path : failed_payway_results_path
        else
          redirect_to order.paid? || @payment.pending? ? order_path(order) : checkout_state_path(:payment)
        end
      end

      def find_payment
        payment_source = Spree::VpagoPaymentSource.find_by(transaction_id: params[:_paymenttokenid])
        @payment = payment_source.payment
      end
    end
  end
end
