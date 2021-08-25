module Spree
  module Wing
    class TransactionsController < BaseController
      before_action :load_payment_source
      def show
        @transaction_status_response = Vpago::WingSdk::TransactionStatusResponse.new(@payment_source)
        @transaction_status_response.call

        render_result
      end

      private
      def load_payment_source
        @payment_source = ::Spree::VpagoPaymentSource.find_by!(transaction_id: params[:id])
      end

      def render_result
        if @transaction_status_response.success?
          render json: @transaction_status_response.result, status: 200
        else
          render json: {response_code: 422, response_msg: 'Unable to load response from wing'}, status: 422
        end
      end
    end
  end
end
