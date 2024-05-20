module Vpago
  module LineItemDecorator
    def self.prepended(base)
      base.has_many :payout_profiles, class_name: 'Spree::PayoutProfile', through: :product
      base.has_many :active_payout_profiles, class_name: 'Spree::PayoutProfile', through: :product
      base.has_many :active_payway_payout_profiles, class_name: 'Spree::PayoutProfile', through: :product
    end

    def required_payway_payout?
      active_payway_payout_profiles.any?
    end
  end
end

Spree::LineItem.prepend(Vpago::LineItemDecorator)
