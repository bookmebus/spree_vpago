# Error reason code:
# - :some_line_items_are_out_of_stock
# - :some_variants_are_discontinued
# - :unable_to_complete_order
# - :invalid_state_machine_transition
# - :unable_to_connect_to_gateway
# - :gateway_error
module Vpago
  class PaymentProcessor
    include PaymentProcessable

    def initialize(payment:)
      @payment = payment
      @error = nil
    end

    def call
      log_process('call!') { call! }
    end

    def call!
      process_payment!
      process_order! if @payment.completed? || @payment.pending?
    rescue Spree::Core::GatewayError => e
      return handle_payment_failure(:unable_to_connect_to_gateway, e.message) if e.message == Spree.t(:unable_to_connect_to_gateway)

      handle_payment_failure(:gateway_error, e.message)
    rescue StateMachines::InvalidTransition => e
      handle_payment_failure(:invalid_state_machine_transition, e.message)
    end

    private

    # payment.process! will throw GatewayError if not success.
    def process_payment!
      log_process('process_payment!') do
        user_informer.payment_is_processing(processing: true)
        @payment.process!
      end
    end

    def process_order!
      log_process('process_order!') do
        user_informer.order_is_processing(processing: true)
        completer = Spree::Checkout::Complete.new.call(order: @payment.order)

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
        @payment.capture! if @payment.pending?
        user_informer.order_is_completed(processing: false)
      end
    end

    def handle_order_process_failure(reason_code, reason_message = nil)
      log_process('handle_order_process_failure', reason_code, reason_message) do
        user_informer.order_process_failed(
          processing: can_cancel_pre_auth?,
          reason_code: reason_code,
          reason_message: reason_message
        )

        cancel_pre_auth(reason_code, reason_message) if can_cancel_pre_auth?
        failure(reason_message)
      end
    end

    def handle_payment_failure(reason_code, reason_message)
      log_process('handle_payment_failure', reason_code, reason_message) do
        user_informer.payment_process_failed(
          processing: can_cancel_pre_auth?,
          reason_code: reason_code,
          reason_message: reason_message
        )

        cancel_pre_auth(reason_code, reason_message) if can_cancel_pre_auth?
        failure(reason_message)
      end
    end
  end
end
