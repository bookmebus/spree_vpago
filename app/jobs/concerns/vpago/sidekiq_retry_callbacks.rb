module Vpago
  # Callbacks for a job retried by Sidekiq itself. ActiveJob's `retry_on` isn't an option for a job with an
  # `until_executed` lock: each retry is a new enqueue, which the job's own lock refuses.
  #
  #   after_failed_attempt Spree::Core::GatewayError, with: :notify_retrying # each failed run; the error is re-raised
  #   after_retries_exhausted with: :notify_gave_up                          # once Sidekiq stops retrying
  #
  # Handlers are private instance methods that read the job's `arguments`. A handler error is logged and never
  # replaces the job's own error, so Sidekiq still retries on the original failure.
  module SidekiqRetryCallbacks
    extend ActiveSupport::Concern

    class_methods do
      def after_failed_attempt(*errors, with:)
        around_perform do |job, block|
          block.call
        rescue *errors => e
          job.send(:run_retry_callback, with)
          raise e
        end
      end

      # Sidekiq-only, so a no-op where the host app doesn't run Sidekiq (e.g. this gem's specs). Sidekiq passes
      # its own payload, which wraps the serialized ActiveJob.
      def after_retries_exhausted(with:)
        return unless respond_to?(:sidekiq_retries_exhausted)

        sidekiq_retries_exhausted do |sidekiq_job, _error|
          serialized_job = sidekiq_job['args'].first
          new(*ActiveJob::Arguments.deserialize(serialized_job['arguments'])).send(:run_retry_callback, with)
        end
      end
    end

    private

    def run_retry_callback(method_name)
      send(method_name)
    rescue StandardError => e
      VpagoLogger.error(
        label: "#{self.class.name}##{method_name} failed",
        data: { arguments: arguments, error_class: e.class.name, error_message: e.message }
      )
    end
  end
end
