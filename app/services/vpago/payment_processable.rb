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

    def log_process(method, *args, &)
      VpagoLogger.log(
        label: "#{self.class.name}##{method}",
        data: {
          payment_number: @payment.number,
          order_number: @payment.order.number,
          payment_method_type: @payment.payment_method.type,
          payment_method_name: @payment.payment_method.name,
          args: args
        },
        &
      )
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
