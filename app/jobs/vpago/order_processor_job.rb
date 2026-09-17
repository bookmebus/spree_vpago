# Put :payment_processing at a higher priority in your project: config/sidekiq.yml
module Vpago
  class OrderProcessorJob < ::ApplicationUniqueJob
    queue_as :payment_processing

    def perform(options)
      order = Spree::Order.find_by!(number: options[:order_number])

      VpagoLogger.log(
        label: 'Vpago::OrderProcessorJob#perform',
        data: { order_number: order.number }
      ) { Vpago::OrderProcessor.new(order: order).call }
    rescue StandardError => e
      VpagoLogger.error(
        label: 'Vpago::OrderProcessorJob#perform failed',
        data: { order_number: options[:order_number], error_class: e.class.name, error_message: e.message, backtrace: e.backtrace&.first(5) }
      )
      raise
    end
  end
end
