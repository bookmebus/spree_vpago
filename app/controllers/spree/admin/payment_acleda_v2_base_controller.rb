module Spree
  module Admin
    class PaymentAcledaV2BaseController < Spree::Admin::BaseController
      include Spree::Backend::Callbacks

      before_action :load_payment, only: %i[show update]
      before_action :validate_order, only: [:update]

      def validate_order
        return unless @payment.order.completed?

        flash[:error] = Spree.t('vpago.payments.not_allow_for_order_completed')
        redirect_to admin_order_payment_path(order_id: @payment.order.number, id: @payment.number)
      end

      def load_payment
        @payment = Payment.find_by!(number: params[:id])
      end
    end
  end
end
