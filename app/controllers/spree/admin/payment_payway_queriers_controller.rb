module Spree
  module Admin
    class PaymentPaywayQueriersController < PaymentPaywayBaseController
      include Spree::Backend::Callbacks
      def show
        tran_status = transaction_status_service.new(@payment)
        tran_status.call

        if tran_status.success?
          flash[:success] = Spree.t('vpago.payments.payment_found_with_result', result: tran_status.result)
        else
          flash[:error] = Spree.t('vpago.payments.payment_not_found_with_error', error: tran_status.error_message)
        end

        redirect_to admin_order_payment_path(order_id: @payment.order.number, id: @payment.number)
      end

      def transaction_status_service
        if @payment.payment_method.type_payway_v2?
          Vpago::PaywayV2::TransactionStatus
        elsif @payment.payment_method.type_payway?
          Vpago::Payway::TransactionStatus
        end
      end
    end
  end
end
