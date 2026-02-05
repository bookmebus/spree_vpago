# Put :payment_processing at a higher priority in your project: config/sidekiq.yml
require 'vpago/timing_helper'

module Vpago
  class PaymentProcessorJob < ::ApplicationUniqueJob
    queue_as :payment_processing

    def perform(options)
      started_at = Vpago::TimingHelper.current_time
      enqueued_at = options[:enqueued_at]
      queue_wait_ms = calculate_queue_wait_ms(enqueued_at)

      log_job_start(options[:payment_number], queue_wait_ms)

      payment = Spree::Payment.find_by!(number: options[:payment_number])
      Vpago::PaymentProcessor.new(payment: payment).call

      log_job_finish(options[:payment_number], queue_wait_ms, started_at)
    rescue StandardError => e
      log_job_error(options[:payment_number], queue_wait_ms, started_at, e)
      raise
    end

    private

    def calculate_queue_wait_ms(enqueued_at)
      return nil unless enqueued_at

      ((Time.now.to_f - enqueued_at.to_f) * 1000.0).round(1)
    end

    def log_job_start(payment_number, queue_wait_ms)
      VpagoLogger.log(
        event: 'vpago.payment_processor_job.start',
        data: {
          payment_number: payment_number,
          queue: self.class.queue_name,
          queue_wait_ms: queue_wait_ms
        }
      )
    end

    def log_job_finish(payment_number, queue_wait_ms, started_at)
      runtime_ms = Vpago::TimingHelper.elapsed_ms(started_at)
      VpagoLogger.log(
        event: 'vpago.payment_processor_job.finish',
        data: {
          payment_number: payment_number,
          queue: self.class.queue_name,
          queue_wait_ms: queue_wait_ms,
          runtime_ms: runtime_ms
        }
      )
    end

    def log_job_error(payment_number, queue_wait_ms, started_at, error)
      runtime_ms = Vpago::TimingHelper.elapsed_ms(started_at)
      VpagoLogger.error(
        event: 'vpago.payment_processor_job.error',
        data: {
          payment_number: payment_number,
          queue: self.class.queue_name,
          queue_wait_ms: queue_wait_ms,
          runtime_ms: runtime_ms,
          error_class: error.class.name,
          error_message: error.message
        }
      )
    end
  end
end
