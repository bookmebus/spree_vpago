module Spree
  module Webhook
    class PaywaysController < BaseController
      skip_before_action :verify_authenticity_token, only: [:return, :v2_return, :continue, :v2_continue]

      # match via: [:get, :post]
      # {"response"=>"{\"tran_id\":\"PE13LXT1\",\"status\":0"}"}
      def v2_return
        handler_service = v2_request_updater_service

        return_callback_handler(handler_service)
      end

      def return
        handler_service = request_updater_service

        return_callback_handler(handler_service)
      end

      # https://vtenh.herokuapp.com/payways/continue?tran_id=P2W2S1LB
      def v2_continue
        continue_callback_handler
      end

      def continue
        continue_callback_handler
      end

      private
      def v2_request_updater_service
        ::Vpago::PaywayV2::PaymentRequestUpdater
      end

      def request_updater_service
        ::Vpago::Payway::PaymentRequestUpdater
      end
      
      # the callback invoke by PAYWAY in case of success
      def return_callback_handler(handler_service)
        # pawway send get request with nothing
        if(request.method == "GET")
          return render plain: :ok
        end

        builder = Vpago::PaywayReturnOptionsBuilder.new(params: params)
        payment = builder.payment

        request_updater = handler_service.new(payment)
        request_updater.call

        order = payment.order
        order = order.reload

        if order.paid? || payment.pending?
          render plain: :success
        else
          render plain: :failed, status: 400
        end
      end

      def continue_callback_handler
        payment = Spree::Payment.find_by number: params[:tran_id]
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
