module Spree
  module Webhook
    class AcledasController < BaseController
      skip_before_action :verify_authenticity_token, only: [:return]

      before_action :find_payment, only: [:success, :error, :return]

      rescue_from ::ActiveRecord::RecordNotFound, with: :record_not_found

      ## call back after transaction complete at acleda system
      ## {"amount": "15.0", "_transactionid"=>"PJ9ETZD4", "_paymentresult"=>"SUCCESS", "_paymenttokenid"=>"lVqWKcLHVk6s0rIgk/T8Vdbzsg0=", "_resultCode"=>"0"}
      def return
        render_plain = true
        check_and_redirect(render_plain)
      end

      ## success
      ## {"_arNo"=>"PJ9ETZD4", "_transactionid"=>"PJ9ETZD4", "_paymentresult"=>"SUCCESS", "_paymenttokenid"=>"lVqWKcLHVk6s0rIgk/T8Vdbzsg0=", "_resultCode"=>"0", "controller"=>"spree/webhook/acledas", "action"=>"success"}
      def success
        check_and_redirect
      end

      def error
        order = @payment.order

        if order.paid?
          flash[:order_completed] = "1" # required by order_just_completed for purchase tracking
        end

        if params[:app_checkout].to_s == '1'
          redirect_to order.paid? || @payment.pending? ? success_payway_results_path : failed_payway_results_path
        else
          redirect_to order.paid? || @payment.pending? ? order_path(order) : checkout_state_path(:payment)
        end
      end

      private
      def check_and_redirect(render_plain=false)
        request_updater = ::Vpago::Acleda::PaymentRequestUpdater.new(@payment)
        request_updater.call

        order = @payment.order
        order = order.reload

        if render_plain
          order.paid? || @payment.pending? ? render(plain: :success) : render(plain: :failed, status: 400)
        else
          redirect_order(order)
        end
      end

      def redirect_order(order)
        if params[:app_checkout].to_s == '1'
          redirect_to order.paid? || @payment.pending? ? success_payway_results_path : failed_payway_results_path
        else
          flash[:order_completed] = "1" if order.paid? # required by order_just_completed for purchase tracking
          redirect_to order.paid? || @payment.pending? ? order_path(order) : checkout_state_path(:payment)
        end
      end

      def find_payment
        @payment = nil
        raise ::ActiveRecord::RecordNotFound if params[:_paymenttokenid].blank?

        payment_source = Spree::VpagoPaymentSource.find_by(transaction_id: params[:_paymenttokenid])
        raise ::ActiveRecord::RecordNotFound if payment_source.blank?

        @payment = payment_source.payment
      end

      def record_not_found
        render(plain: :payment_not_found, status: 404)
      end
    end
  end
end
