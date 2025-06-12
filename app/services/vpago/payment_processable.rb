module Vpago
  module PaymentProcessable
    def cancel_pre_auth(reason_code, reason_message)
      log_process('cancel_pre_auth') do
        @payment.void_transaction!
        user_informer.payment_is_refunded(
          processing: false,
          reason_code: reason_code,
          reason_message: reason_message
        )
      end
    end

    # Allows canceling pre-authorization if:
    # 1. The payment is pending or authorized.
    # 2. Pre-auth is enabled, ensuring funds can be released to user if processing fails.
    #    PaymentProcessor is usually called after payment is made, so canceling pre-auth typically works.
    def can_cancel_pre_auth?
      @payment.pending? || @payment.payment_method.enable_pre_auth? || @payment.vattanac_mini_app_payment?
    end

    def extract_completer_failure_reason_code(error)
      return :some_line_items_are_out_of_stock if error.respond_to?(:to_h) && error.to_h[:base]&.include?(Spree.t(:insufficient_stock_lines_present))
      return :some_variants_are_discontinued if error.respond_to?(:to_h) && error.to_h[:base]&.include?(Spree.t(:discontinued_variants_present))

      :unable_to_complete_order
    end

    # example.
    # Started Vpago::PaymentProcessor#process_payment! for payment_number: PX81YZX with args: {}
    # Completed Vpago::PaymentProcessor#process_payment! for payment_number: PX81YZX in 2000ms
    def log_process(method, *args)
      start_time = Time.now
      Rails.logger.error("Started #{self.class}##{method} for payment_number: #{@payment.number} with args: #{args}")

      yield

      duration_ms = (Time.now - start_time) * 1000
      Rails.logger.error("Completed #{self.class}##{method} for payment_number: #{@payment.number} in #{duration_ms}ms")
    end

    def user_informer
      @user_informer ||= ::Vpago::UserInformers::Firebase.new(@payment.order)
    end

    def success?
      @error.nil?
    end

    def failure(error)
      @error = error
    end
  end
end
