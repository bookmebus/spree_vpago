module Spree
  module Webhook
    class PaywaysController < BaseController
      skip_before_action :verify_authenticity_token, only: [:return, :continue]
  
      # match via: [:get, :post]
      # {"response"=>"{\"tran_id\":\"PE13LXT1\",\"status\":0"}"}
      def return

        # pawway send get request with nothing
        if(request.method == "GET")
          return render plain: :ok
        end

        # the callback invoke by PAYWAY in case of success
        payload = JSON.parse(params[:response])
        payment = Spree::Payment.find_by(number: payload["tran_id"])

        request_updater = ::Vpago::Payway::PaymentRequestUpdater.new(payment)
        request_updater.call

        order = payment.order
        order = order.reload

        if order.paid? || payment.pending?
          render plain: :success
        else
          render plain: :failed, status: 400
        end

      end

      # https://vtenh.herokuapp.com/payways/continue?tran_id=P2W2S1LB
      def continue
        payment = Spree::Payment.find_by number: params[:tran_id]
        order = payment.order

        if order.paid?
          flash[:order_completed] = "1" # required by order_just_completed for purchase tracking
        end

        redirect_to order.paid? || payment.pending? ? order_path(order) : checkout_state_path(:payment)
      end
    end
  
  end
end
