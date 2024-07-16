module Spree
  class PayoutProfileProduct < Base
    belongs_to :payout_profile, class_name: 'Spree::PayoutProfile', inverse_of: :payout_profile_products
    belongs_to :product, class_name: 'Spree::Product', inverse_of: :payout_profile_products

    validates :payout_profile, presence: true
    validates :product, presence: true

    validates :payout_profile_id, uniqueness: { scope: :product_id }
  end
end
