module Spree
  module Admin
    class PaymentPaywayQueriersController < PaymentPaywayBaseController
      include Spree::Backend::Callbacks

      around_action :set_writing_role, only: %i[show]

      def show
        tran_status = @payment.payment_method.check_transaction(@payment)

        if tran_status.success?
          @payment.update_column(:gateway_status, true)
          flash[:success] =
            Spree.t('vpago.payments.payment_found_with_result', result: tran_status.json_response)
        else
          flash[:error] = Spree.t('vpago.payments.payment_not_found_with_error', error: tran_status.error_message)
        end

        redirect_to admin_order_payment_path(order_id: @payment.order.number, id: @payment.number)
      end

      private

      def set_writing_role
        ActiveRecord::Base.connected_to(role: :writing) do
          yield if block_given?
        end
      end
    end
  end
end
