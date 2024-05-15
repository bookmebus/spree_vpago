module Vpago
  module LineItemDecorator
    def self.prepended(base)
      base.has_many :payout_profiles, class_name: 'Spree::PayoutProfile', through: :product
    end
  end
end

Spree::LineItem.prepend(Vpago::LineItemDecorator)
