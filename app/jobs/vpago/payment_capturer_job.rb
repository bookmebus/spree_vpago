# Put :payment_processing at a higher priority in your project: config/sidekiq.yml
module Vpago
  class PaymentCapturerJob < ::ApplicationUniqueJob
    queue_as :payment_processing

    def perform(payment_id)
      payment = Spree::Payment.find(payment_id)
      payment.capture! if payment.pending?
    end
  end
end
