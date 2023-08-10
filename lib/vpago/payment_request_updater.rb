module Vpago
  class PaymentRequestUpdater
    attr_accessor :payment, :error_message

    def initialize(payment, options={})
      @options = options
      @payment = payment
      @error_message = nil
    end

    def success?
      @error_message.nil?
    end
  end
end
