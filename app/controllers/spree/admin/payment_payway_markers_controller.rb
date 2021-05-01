module Spree
  module Admin
    class PaymentPaywayMarkersController < PaymentPaywayBaseController
      include Spree::Backend::Callbacks

      def update
        reason = params[:updated_reason]&.strip

        if(reason.blank?)
          flash[:error] = Spree.t('vpago.payments.failed_require_updated_reason')
          return redirect_to admin_order_payment_path(order_id: @payment.order.number, id: @payment.number)
        end

        options = {
          updated_by_user_id: try_spree_current_user.id,
          updated_reason: reason,
          status: true,
          description: "vpago.payments.mark_with_reason"
        }
        spree_updater = Vpago::Payway::PaymentStatusMarker.new(@payment, options)
        spree_updater.call

        @payment.reload

        if @payment.order.completed?
          flash[:success] = Spree.t(:successfully_updated, resource: Spree.t(:payments))
        else
          flash[:error] = Spree.t(:unsuccessfully_updated, resource: Spree.t(:payments))
        end

        redirect_to admin_order_payment_path(order_id: @payment.order.number, id: @payment.number)
      end
    end
  end
end
