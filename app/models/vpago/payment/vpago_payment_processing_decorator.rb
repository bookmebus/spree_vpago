module Vpago
  module Payment
    module VpagoPaymentProcessingDecorator
      def process!
        if is_vpago_type?
          process_with_vpago_gateway
        else
          super
        end
      end

      def cancel!
        if is_vpago_type?
          cancel_with_vpago_gateway
        else
          super
        end
      end

      # private
      def is_vpago_type?
        payment_method.is_a?(Spree::Gateway::Payway) || payment_method.is_a?(Spree::Gateway::WingSdk) || 
        payment_method.is_a?(Spree::Gateway::Acleda)
      end

      def cancel_with_vpago_gateway
        response = payment_method.cancel(transaction_id)
        handle_response(response, :void, :failure)
      end

      def process_with_vpago_gateway
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

Spree::Payment.include(Vpago::Payment::VpagoPaymentProcessingDecorator)
