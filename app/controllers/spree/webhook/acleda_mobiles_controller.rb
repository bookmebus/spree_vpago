module Spree
  module Webhook
    class AcledaMobilesController < BaseController
      skip_before_action :verify_authenticity_token
      before_action :find_payment, only: [:return]

      # {
      #   "TransactionId": "REF0361472663",
      #   "PaymentTokenId": "16de81d4-b5ef-ef59-16de-81d4b5efef59",
      #   "TxnAmount": "30",
      #   "SenderName": "Test User",
      #   "SignedHash": "c5b9be690bde7dc8a0abebb1a45c0850359540a4977aecd4cdf13e15a2edfe79"
      #   }
      def return
        request_updater = ::Vpago::AcledaMobile::PaymentRequestUpdater.new(@payment)
        request_updater.call

        order = @payment.order
        order = order.reload

        if order.paid? || @payment.pending?
          render_success
        else
          render_failed
        end
      end

      private

      def find_payment
        options = params.slice(:TransactionId, :PaymentTokenId, :TxnAmount, :SenderName, :SignedHash)
        service = Vpago::AcledaMobile::PaymentRetriever.new(options)
        service.call

        return render_failed if !service.data_valid?

        @payment = service.payment
        return render_payment_not_found if @payment.blank?
      end

      def render_success
        status_code = 200
        response_data = acleda_mobile_response_data('Success', status_code)

        acleda_mobile_response(response_data, status_code)
      end

      def render_failed
        status_code = 201
        response_data = acleda_mobile_response_data('Failed', status_code)

        acleda_mobile_response(response_data, status_code)
      end

      def render_payment_not_found
        status_code = 203
        response_data = acleda_mobile_response_data('Payment not found', status_code)

        acleda_mobile_response(response_data, status_code)
      end

      def acleda_mobile_response(response_data, status_code)
        render json: response_data, status: status_code
      end
      
      def acleda_mobile_response_data(message, code)
        {
          status: {
            code: code,
            message: message
          },
          data: {
            TransactionId: params[:TransactionId],
            PaymentTokenId: params[:PaymentTokenId]
          }
        }
      end
    end
  end
end
