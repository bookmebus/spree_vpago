module Vpago
  module ProductDecorator
    def self.prepended(base)
      base.has_many :payout_profile_products, class_name: 'Spree::PayoutProfileProduct', inverse_of: :product
      base.has_many :payout_profiles, class_name: 'Spree::PayoutProfile', through: :payout_profile_products
    end
  end
end

Spree::Product.prepend(Vpago::ProductDecorator)
