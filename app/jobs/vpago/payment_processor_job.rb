module Vpago
  class PaymentProcessorJob < ::ApplicationUniqueJob
    def perform(options)
      payment = Spree::Payment.find_by(number: options[:payment_number])
      Vpago::PaymentProcessor.new(payment: payment).call
    end
  end
end
