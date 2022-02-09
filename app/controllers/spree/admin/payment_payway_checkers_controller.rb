module Spree
  module Admin
    class PaymentPaywayCheckersController < PaymentPaywayBaseController
      include Spree::Backend::Callbacks
      def update
        options = {
          updated_by_user_id: try_spree_current_user.id,
          updated_reason: Spree.t('vpago.payments.checker_updated_by_description') 
        }
        spree_updater = payment_request_update_service.new(@payment, options)
        spree_updater.call

        @payment.reload

        if @payment.order.completed?
          flash[:success] = Spree.t(:successfully_updated, resource: Spree.t(:payments))
        else
          flash[:error] = Spree.t(:unsuccessfully_updated, resource: Spree.t(:payments))
        end

        redirect_to admin_order_payment_path(order_id: @payment.order.number, id: @payment.number)
      end

      def payment_request_update_service
        if @payment.payment_method.type_payway_v2?
          Vpago::PaywayV2::PaymentRequestUpdater
        elsif @payment.payment_method.type_payway?
          Vpago::Payway::PaymentRequestUpdater
        end
      end
    end
  end
end
