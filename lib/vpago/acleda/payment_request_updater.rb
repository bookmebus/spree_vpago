module Vpago
  module Acleda
    class PaymentRequestUpdater < ::Vpago::PaymentRequestUpdater
      def call
        return if @payment.order.paid?

        checker = payment_status_checker

        if(checker.success?)
          @error_message = nil
          checker_result = {
            status: true,
            description: nil,
            acleda_response: checker.result,
          }
          marker_options = @options.merge(checker_result)

          marker = ::Vpago::PaymentStatusMarker.new(@payment, marker_options)
          marker.call
        elsif !ignore_on_failed?
          @error_message = checker.error_message
          marker_options = @options.merge(status: false, description: @error_message)

          marker = ::Vpago::PaymentStatusMarker.new(@payment, marker_options)
          marker.call
        end
      end

      private
      def payment_status_checker
        trans_status = Vpago::Acleda::TransactionStatus.new(@payment)
        trans_status.call
        trans_status
      end
    end
  end
end
