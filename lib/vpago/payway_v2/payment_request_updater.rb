module Vpago
  module PaywayV2
    class PaymentRequestUpdater < ::Vpago::PaymentRequestUpdater
      def call
        return if @payment.order.paid?

        checker = check_payway_status

        if(checker.success?)
          @error_message = nil
          checker_result = {
            status: true,
            description: nil,
            payway_v2_response: checker.result,
          }
          marker_options = @options.merge(checker_result)

          marker = ::Vpago::PaymentStatusMarker.new(@payment, marker_options)
          marker.call
        else
          @error_message = checker.error_message
          marker_options = @options.merge(status: false, description: @error_message)

          marker = ::Vpago::PaymentStatusMarker.new(@payment, marker_options)
          marker.call
        end
      end

      def check_payway_status
        trans_status = Vpago::PaywayV2::TransactionStatus.new(@payment)
        trans_status.call
        trans_status
      end
    end
  end
end
