module Vpago
  module Vattanac
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

      def process_payment_status
        checker = @payment.payment_method.check_transaction(@payment)

        if checker.success?
          mark_payment_as_success
        elsif checker.failed? && !ignore_on_failed?
          mark_payment_as_failed(checker.error_message)
        end
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
        VpagoLogger.error(
          label: 'Vpago::Vattanac::PaymentRequestUpdater#process_payment_status gateway_timeout',
          data: { payment_number: @payment.number, error_class: e.class.name, error_message: e.message }
        )
      end

      def items_eligible?
        @payment&.order&.line_items&.all?(&:sufficient_stock?) == true # rubocop:disable Style/SafeNavigationChainLength
      end

      def mark_items_as_ineligible
        @error_message = 'Items are not eligible due to insufficient stock'
        marker_options = @options.merge(status: false, description: @error_message)
        ::Vpago::PaymentStatusMarker.new(@payment, marker_options).call
      end

      def mark_payment_as_success
        @error_message = nil
        marker_options = @options.merge(status: true, description: nil)
        ::Vpago::PaymentStatusMarker.new(@payment, marker_options).call
      end

      def mark_payment_as_failed(error_message)
        @error_message = error_message
        marker_options = @options.merge(status: false, description: @error_message)
        ::Vpago::PaymentStatusMarker.new(@payment, marker_options).call
      end
    end
  end
end
