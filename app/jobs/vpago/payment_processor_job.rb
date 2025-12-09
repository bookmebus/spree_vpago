# Put :payment_processing at a higher priority in your project: config/sidekiq.yml
module Vpago
  class PaymentProcessorJob < ::ApplicationUniqueJob
    queue_as :payment_processing

    def perform(options)
      payment = Spree::Payment.find_by!(number: options[:payment_number])
      Vpago::PaymentProcessor.new(payment: payment).call
    end
  end
end
