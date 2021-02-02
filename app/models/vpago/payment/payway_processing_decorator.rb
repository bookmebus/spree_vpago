module Vpago
  module Payment
    module PaywayProcessingDecorator
      def process!
        if payment_method.is_a? Spree::Gateway::Payway
          process_with_payway_gateway
        else
          super
        end
      end

      def cancel!
        if payment_method.is_a? Spree::Gateway::Payway
          cancel_with_payway_gateway
        else
          super
        end
      end

      # private

      def cancel_with_payway_gateway
        response = payment_method.cancel(transaction_id)
        handle_response(response, :void, :failure)
      end

      def process_with_payway_gateway
        amount ||= money.money
        started_processing!

        response = payment_method.process(
          amount,
          source,
          gateway_options
        )
        handle_response(response, :started_processing, :failure)
      end
    end
  end
end

Spree::Payment.include(Vpago::Payment::PaywayProcessingDecorator)