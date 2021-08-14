module Spree
  module Webhook
    class WingsController < BaseController
      skip_before_action :verify_authenticity_token, only: [:return, :continue, :create]
      before_action :retrive_payment, only: [:create]
      before_action :find_payment, only: [:return, :continue,]

      def create
        render_plain = true
        check_and_redirect(render_plain)
      end
      
      ## click on button Done: POST { wing_id: payment_number, response: {"remark"=>"PNRE5V5E", "amount"=>" USD 30.00", "total"=>" USD 30.00", "transaction_id"=>"ONL031157", "customer_name"=>"Wing Testing WCX-USD", "biller_name"=>"VTENH"}}
      ## click on button Back: GET  { wing_id: payment_number }
      def return
        check_and_redirect
      end

      private
      def find_payment
        @payment = ::Spree::Payment.find_by(number: params[:wing_id])
      end

      def retrive_payment
        wing_payment_method = Spree::PaymentMethod.find_by(type: Spree::PaymentMethod::TYPE_WINGSDK)
        rest_api_key = wing_payment_method.preferences[:rest_api_key]
        wing_response = params[:contents]

        payment_retriever = ::Vpago::WingSdk::PaymentRetriever.new(rest_api_key, wing_response)
        payment_retriever.call

        @payment = payment_retriever.payment
      end

      def check_and_redirect(render_plain=false)
        request_updater = ::Vpago::WingSdk::PaymentRequestUpdater.new(@payment)
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
        if params[:app_checkout] == 'yes'
          redirect_to order.paid? || @payment.pending? ? success_payment_results_path : failed_payment_results_path
        else
          flash[:order_completed] = "1" if order.paid? # required by order_just_completed for purchase tracking
          redirect_to order.paid? || @payment.pending? ? order_path(order) : checkout_state_path(:payment)
        end
      end
    end
  end
end
