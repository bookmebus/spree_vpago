# Put :payment_processing at a higher priority in your project: config/sidekiq.yml
module Vpago
  class PaymentCancelerJob < ::ApplicationUniqueJob
    queue_as :payment_processing

    def perform(payment_id)
      payment = Spree::Payment.find(payment_id)
      payment.cancel! if payment.actions.include?('cancel')
    end
  end
end
