module Vpago
  module ProductDecorator
    def self.prepended(base)
      base.has_many :payout_profile_products,
                    class_name: 'Spree::PayoutProfileProduct', inverse_of: :product

      base.has_many :payout_profiles,
                    class_name: 'Spree::PayoutProfile', through: :payout_profile_products,
                    source: :payout_profile

      base.has_many :active_payout_profiles, -> { verified.active },
                    class_name: 'Spree::PayoutProfile',
                    through: :payout_profile_products, source: :payout_profile

      base.has_many :active_payway_payout_profiles, -> { payway.verified.active },
                    class_name: 'Spree::PayoutProfile',
                    through: :payout_profile_products, source: :payout_profile

      base.has_many :required_payout_profile_products, -> { required },
                    class_name: 'Spree::PayoutProfileProduct',
                    inverse_of: :product

      base.has_many :required_active_payout_profiles, -> { verified.active },
                    class_name: 'Spree::PayoutProfile',
                    through: :required_payout_profile_products, source: :payout_profile
    end
  end
end

Spree::Product.prepend(Vpago::ProductDecorator)
