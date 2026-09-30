module Spree
  module Admin
    class SuspiciousOrdersController < Spree::Admin::BaseController
      around_action :set_writing_role, only: %i[check_transaction]

      def index
        params[:q] = { completed_at_not_null: 1, payment_state_eq: 'balance_due', s: 'completed_at desc' }.dup if params[:q].blank?

        @search = scope.ransack(params[:q])
        @orders = @search.result(distinct: true)
                         .preload(:payments, :reimbursements)
                         .page(params[:page])
                         .per(params[:per_page] || Spree::Backend::Config[:admin_orders_per_page])
      end

      def payments
        @order = scope.find_by!(number: params[:id])
        @payments = @order.payments.includes(:payment_method)

        render layout: false
      end

      # Renders the result inline into this order's payments frame instead of
      # redirecting, so the admin never leaves this list.
      def check_transaction
        @order = scope.find_by!(number: params[:id])
        payment = @order.payments.find_by!(number: params[:payment_number])

        @check_result = query_payment_transaction(payment)
        @payments = @order.payments.includes(:payment_method)

        render 'payments', layout: false
      end

      private

      # Delegates to the gateway's own check_transaction (same method
      # PaywayV2/Vattanac/TrueMoney already implement) - no per-gateway
      # branching needed here.
      def query_payment_transaction(payment)
        method = payment.payment_method
        return nil unless method.support_check_transaction_api?

        result = method.check_transaction(payment)

        # Not every gateway's checker implements error_message (e.g. Vattanac,
        # TrueMoney) - fall back to the raw response so this doesn't blow up
        # for gateways that only implement the minimal success?/json_response duck type.
        message =
          if result.success?
            Spree.t('vpago.payments.payment_found_with_result', result: result.try(:json_response))
          else
            Spree.t('vpago.payments.payment_not_found_with_error', error: result.try(:error_message) || result.try(:json_response))
          end

        { success: result.success?, message: message }
      end

      def scope
        current_store.orders.accessible_by(current_ability, :index)
      end
    end
  end
end
