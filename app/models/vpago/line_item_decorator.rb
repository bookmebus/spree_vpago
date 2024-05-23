module Vpago
  module LineItemDecorator
    def self.prepended(base)
      base.has_many :payout_profiles, class_name: 'Spree::PayoutProfile', through: :product
      base.has_many :active_payout_profiles, class_name: 'Spree::PayoutProfile', through: :product
      base.has_many :active_payway_payout_profiles, class_name: 'Spree::PayoutProfile', through: :product

      base.has_many :required_active_payout_profiles, class_name: 'Spree::PayoutProfile', through: :product
    end

    # considred required when there are any required profiles.
    def required_payway_payout?
      required_active_payout_profiles.payway.exists?
    end
  end
end

Spree::LineItem.prepend(Vpago::LineItemDecorator)
