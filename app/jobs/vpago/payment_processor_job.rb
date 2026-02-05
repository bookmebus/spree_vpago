# Put :payment_processing at a higher priority in your project: config/sidekiq.yml
require 'vpago/timing_helper'

module Vpago
  class PaymentProcessorJob < ::ApplicationUniqueJob
    queue_as :payment_processing

    def perform(options)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      enqueued_at = options[:enqueued_at]
      queue_wait_ms = if enqueued_at
                        ((Time.now.to_f - enqueued_at.to_f) * 1000.0).round(1)
                      end

      Rails.logger.info(
        {
          event: 'vpago.payment_processor_job.start',
          payment_number: options[:payment_number],
          queue: self.class.queue_name,
          queue_wait_ms: queue_wait_ms
        }
      )

      payment = Spree::Payment.find_by!(number: options[:payment_number])
      Vpago::PaymentProcessor.new(payment: payment).call

      runtime_ms = Vpago::TimingHelper.elapsed_ms(started_at)
      Rails.logger.info(
        {
          event: 'vpago.payment_processor_job.finish',
          payment_number: options[:payment_number],
          queue: self.class.queue_name,
          queue_wait_ms: queue_wait_ms,
          runtime_ms: runtime_ms
        }
      )
    rescue StandardError => e
      runtime_ms = Vpago::TimingHelper.elapsed_ms(started_at)
      Rails.logger.error(
        {
          event: 'vpago.payment_processor_job.error',
          payment_number: options[:payment_number],
          queue: self.class.queue_name,
          queue_wait_ms: queue_wait_ms,
          runtime_ms: runtime_ms,
          error_class: e.class.name,
          error_message: e.message
        }
      )
      raise
    end
  end
end
