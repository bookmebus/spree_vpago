module Spree
  class Payout < Base
    belongs_to :payout_profile, class_name: 'Spree::PayoutProfile', required: true, inverse_of: :payouts
    belongs_to :line_item, class_name: 'Spree::LineItem', required: false, inverse_of: :payouts
    belongs_to :payment, class_name: 'Spree::Payment', required: true, inverse_of: :payouts

    enum state: { created: 0, confirmed: 1 }

    validates :payout_profile_id, uniqueness: { scope: %i[line_item_id payment_id] }

    extend DisplayMoney
    money_methods :amount, :outstanding_amount
  end
end
