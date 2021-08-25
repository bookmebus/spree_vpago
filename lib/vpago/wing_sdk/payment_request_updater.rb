module Vpago
  module WingSdk
    class PaymentRequestUpdater
      attr_accessor :payment, :error_message

      def initialize(payment, options={})
        @options = options
        @payment = payment
      end

      def call
        return if @payment.order.paid?

        checker = check_wing_status

        if(checker.success?)
          @error_message = nil
          checker_result = {
            status: true,
            description: nil,
            transaction_id: checker.result["transaction_id"],
            wing_response: checker.result
          }
          marker_options = @options.merge(checker_result)

          marker = ::Vpago::PaymentStatusMarker.new(@payment, marker_options)
          marker.call
        else
          @error_message = checker.error_message[0...255]
          marker_options = @options.merge(status: false, description: @error_message)

          marker = ::Vpago::PaymentStatusMarker.new(@payment, marker_options)
          marker.call
        end
      end

      def ensure_payment
        return if @payment.present?

        @payment = find_payment
      end

      def success?
        @error_message.nil?
      end

      private
      def check_wing_status
        trans_status = Vpago::WingSdk::TransactionStatusChecker.new(@payment)
        trans_status.call
        trans_status
      end
    end
  end
end
