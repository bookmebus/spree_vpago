# Put :payment_processing at a higher priority in your project: config/sidekiq.yml
module Vpago
  class PaymentVoiderJob < ::ApplicationUniqueJob
    queue_as :payment_processing

    def perform(payment_id)
      payment = Spree::Payment.find(payment_id)
      payment.void_transaction! if payment.actions.include?('void')
    end
  end
end
