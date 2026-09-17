# Order-based counterpart to Vpago::PaymentProcessor, for orders where order_total_after_store_credit
# is zero -- store credit covering the order in full, cash-on with nothing left to pay after store
# credit, or a free event. None of these need a Spree::Payment processed (there may be no payment
# record at all, e.g. free events), only the order completed -- so this only runs the process_order!
# half of PaymentProcessor#call!, reusing the same completer + Firebase user-informer flow so the
# vpago_orders webview (processing -> success) behaves like vpago_payments for the client.
#
# Error reason code:
# - :some_line_items_are_out_of_stock
# - :some_variants_are_discontinued
# - :unable_to_complete_order
# - :invalid_state_machine_transition
module Vpago
  class OrderProcessor
    def initialize(order:)
      @order = order
      @error = nil
    end

    def call
      log_process('call!') { call! }
    end

    def call!
      process_order!
    rescue StateMachines::InvalidTransition => e
      handle_order_process_failure(:invalid_state_machine_transition, e.message)
    end

    def success?
      @error.nil?
    end

    private

    def process_order!
      log_process('process_order!') do
        user_informer.order_is_processing(processing: true)
        completer = Spree::Checkout::Complete.new.call(order: @order)

        if completer.success?
          handle_order_process_completed
        else
          reason_code = extract_completer_failure_reason_code(completer.error)
          handle_order_process_failure(reason_code, completer.error.to_s)
        end
      end
    end

    def handle_order_process_completed
      log_process('handle_order_process_completed') do
        user_informer.order_is_completed(processing: false)
      end
    end

    def handle_order_process_failure(reason_code, reason_message = nil)
      log_process('handle_order_process_failure', reason_code, reason_message) do
        user_informer.order_process_failed(
          processing: false,
          reason_code: reason_code,
          reason_message: reason_message
        )

        failure(reason_message)
      end
    end

    def extract_completer_failure_reason_code(error)
      return :some_line_items_are_out_of_stock if error.respond_to?(:to_h) && error.to_h[:base]&.include?(Spree.t(:insufficient_stock_lines_present))
      return :some_variants_are_discontinued if error.respond_to?(:to_h) && error.to_h[:base]&.include?(Spree.t(:discontinued_variants_present))

      :unable_to_complete_order
    end

    def log_process(method, *args, &)
      VpagoLogger.log(
        label: "#{self.class.name}##{method}",
        data: { order_number: @order.number, args: args },
        &
      )
    end

    def user_informer
      @user_informer ||= ::Vpago::UserInformers::Firebase.new(@order)
    end

    def failure(error)
      @error = error
    end
  end
end
