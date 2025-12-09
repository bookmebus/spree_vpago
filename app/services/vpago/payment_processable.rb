module Vpago
  module PaymentProcessable
    def enqueue_capture_payment_if_available!
      Vpago::PaymentCapturerJob.perform_later(@payment.id) if available_actions.include?('capture')
    end

    def enqueue_void_or_cancel_payment_if_available!
      if available_actions.include?('void')
        Vpago::PaymentVoiderJob.perform_later(@payment.id)
      elsif available_actions.include?('cancel')
        Vpago::PaymentCancelerJob.perform_later(@payment.id)
      end
    end

    # To check available actions, see app/models/spree/vpago_payment_source.rb
    def available_actions
      @payment.actions
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
