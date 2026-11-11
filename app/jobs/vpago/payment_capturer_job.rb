# Put :payment_processing at a higher priority in your project: config/sidekiq.yml
module Vpago
  class PaymentCapturerJob < ::ApplicationUniqueJob
    include Vpago::SidekiqRetryCallbacks

    queue_as :payment_processing

    # A failed capture raises, so Sidekiq retries it. Pinned here rather than left to the host app's
    # max_retries, because the count sets how long the processing page says "taking a little longer"
    # before "not confirmed": 5 retries run for ~8 minutes with Sidekiq's default backoff.
    sidekiq_options retry: 5 if respond_to?(:sidekiq_options)

    # The default 1-day lock outlives a job that exhausted its retries and would silently refuse every
    # re-enqueue for this payment (ABA pushback, a repair run) until the next day; 30 minutes covers the
    # retry window above. The host app's ApplicationUniqueJob provides `unique`, spree_vpago doesn't.
    unique :until_executed, lock_ttl: 30.minutes, on_conflict: :log if respond_to?(:unique)

    # Keeps the processing page honest while Sidekiq retries a pre-auth capture.
    after_failed_attempt Spree::Core::GatewayError, with: :notify_capture_retrying
    after_retries_exhausted with: :give_up_capture

    def perform(payment_id)
      @payment = Spree::Payment.find(payment_id)
      payment.capture! if payment.actions.include?('capture')

      # The processing page holds a pre-auth payment on "verifying" until this message arrives (see
      # PaymentProcessor#notify_order_completed). Keyed on the result rather than on this run's capture,
      # so a retry after a failed Firestore write still sends it.
      payment.user_informer.order_is_completed(processing: false) if payment.payment_method.enable_pre_auth? && payment.completed?
    end

    private

    def notify_capture_retrying
      return unless payment&.awaiting_pre_auth_capture?

      payment.user_informer.payment_capture_retrying(processing: true)
    end

    # Frees the lock now rather than at its TTL, so the page's reload (or ABA pushback) can start a new
    # capture straight away. Released after the page is told, so a reload racing this can't have its
    # "verifying" overwritten by "not confirmed".
    def give_up_capture
      notify_capture_unconfirmed
    ensure
      self.class.unlock!(*arguments) if self.class.respond_to?(:unlock!)
    end

    # Skipped when the capture itself succeeded and only the later Firestore write kept failing.
    def notify_capture_unconfirmed
      return unless payment&.awaiting_pre_auth_capture?

      payment.user_informer.payment_capture_unconfirmed(processing: false)
    end

    def payment
      @payment ||= Spree::Payment.find_by(id: arguments.first)
    end
  end
end
