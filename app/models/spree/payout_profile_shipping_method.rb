module Spree
  class PayoutProfileShippingMethod < Base
    scope :required, -> { where(optional: false) }
    scope :optional, -> { where(optional: true) }

    belongs_to :payout_profile, class_name: 'Spree::PayoutProfile', inverse_of: :payout_profile_shipping_methods
    belongs_to :shipping_method, class_name: 'Spree::ShippingMethod', inverse_of: :payout_profile_shipping_methods

    validates :payout_profile, presence: true
    validates :shipping_method, presence: true

    validates :payout_profile_id, uniqueness: { scope: :shipping_method_id }
  end
end
