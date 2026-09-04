# Put :payment_processing at a higher priority in your project: config/sidekiq.yml
module Vpago
  class PaymentProcessorJob < ::ApplicationUniqueJob
    queue_as :payment_processing

    def perform(options)
      payment = Spree::Payment.find_by!(number: options[:payment_number])

      VpagoLogger.log(
        label: 'Vpago::PaymentProcessorJob#perform',
        data: {
          payment_number: payment.number,
          order_number: payment.order.number,
          payment_method_type: payment.payment_method.type,
          payment_method_name: payment.payment_method.name
        }
      ) { Vpago::PaymentProcessor.new(payment: payment).call }
    rescue StandardError => e
      VpagoLogger.error(
        label: 'Vpago::PaymentProcessorJob#perform failed',
        data: { payment_number: options[:payment_number], error_class: e.class.name, error_message: e.message, backtrace: e.backtrace&.first(5) }
      )
      raise
    end
  end
end
