module Vpago
  module Payway
    class PaymentStatusUpdater
      attr_accessor :payment

      def initialize(payment)
        @payment = payment
      end

      def call
        prepare_and_load_payway_status
        update_payment_source
        update_payment_and_order
      end

      def check_payway_status
        trans_status = Vpago::Payway::TransactionStatus.new(@payment)
        trans_status.call
        trans_status
      end

      def prepare_and_load_payway_status
        @error_message = nil
        @payway_trans_status = check_payway_status
      end

      def success?
        @payment.source.payment_status == "success"
      end

      def error_message
        success? ? nil :  @payment.source.payment_description
      end

      private

      def update_payment_source
        source = @payment.source

        if @payway_trans_status.success?
          source.payment_status = 'success'
          source.payment_description = 'success'
          source.save
        else
          source.payment_status = 'failed'
          source.payment_description = @payway_trans_status.error_message[0...255]
          source.save
        end
      end

      def update_payment_and_order
        if @payway_trans_status.success?
          transition_to_paid!
        else
          transition_to_failed!
        end
        
        order_updater
      end

      def transition_to_paid!
        return if @payment.completed?

        complete_payment!
        complete_order!
      end

      def transition_to_failed!
        @payment.failure! if !@payment.failed?
        @payment.order.update(state: 'payment', completed_at: nil)
        
        notify_failed_payment
      end

      def order_updater
        @payment.order.update_with_updater!
      end

      def complete_payment!
        @payment.complete!
      end

      def complete_order!
        return if @payment.order.completed?
        @payment.order.finalize!
        @payment.order.update(state: 'complete', completed_at: Time.zone.now)
      end

      def notify_failed_payment
        Rails.logger.debug("Gateway error check with: #{@payway_trans_status.error_message} and will be marked as failed")
      end
    end
  end
end
