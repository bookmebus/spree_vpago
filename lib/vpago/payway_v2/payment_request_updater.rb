module Vpago
  module PaywayV2
    class PaymentRequestUpdater < ::Vpago::PaymentRequestUpdater
      def call
        return if @payment.order.paid?

        if items_eligible?
          process_payment_status
        else
          mark_items_as_ineligible
        end
      end

      private

      def mark_items_as_ineligible
        @error_message = 'Items are not eligible due to insufficient stock'
        marker_options = @options.merge(status: false, description:  @error_message)
        marker = ::Vpago::PaymentStatusMarker.new(@payment, marker_options)
        marker.call
      end

      def process_payment_status
        checker = check_payway_status

        if checker.success?
          mark_payment_as_success(checker)
        elsif checker.failed?
          mark_payment_as_failed(checker.error_message)
        end
      end

      def mark_payment_as_success(checker)
        @error_message = nil
        checker_result = {
          status: true,
          description: nil,
          payway_v2_response: checker.json_response,
          payout_total: checker.payout_total
        }
        marker_options = @options.merge(checker_result)
        marker = ::Vpago::PaymentStatusMarker.new(@payment, marker_options)
        marker.call
      end

      def mark_payment_as_failed(error_message)
        @error_message = error_message
        marker_options = @options.merge(status: false, description: @error_message)

        marker = ::Vpago::PaymentStatusMarker.new(@payment, marker_options)
        marker.call
      end

      def check_payway_status
        trans_status = Vpago::PaywayV2::TransactionStatus.new(@payment)
        trans_status.call
        trans_status
      end

      def items_eligible?
        @payment&.order&.line_items&.all?(&:sufficient_stock?) == true
      end
    end
  end
end
