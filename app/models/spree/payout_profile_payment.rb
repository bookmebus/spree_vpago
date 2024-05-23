module Spree
  class PayoutProfilePayment < Base
    belongs_to :payout_profile, class_name: 'Spree::PayoutProfile', required: true, inverse_of: :payout_profile_payments
    belongs_to :payment, class_name: 'Spree::Payment', required: true, inverse_of: :payout_profile_payments
  end
end
