module Vpago
  module ShippingMethodDecorator
    def self.prepended(base)
      base.enum handle_by: { store: 0, vendor: 1 }, _prefix: true

      base.has_many :payout_profile_shipping_methods,
                    class_name: 'Spree::PayoutProfileShippingMethod',
                    inverse_of: :shipping_method

      base.has_many :payout_profiles,
                    class_name: 'Spree::PayoutProfile', through: :payout_profile_shipping_methods,
                    source: :payout_profile

      base.has_many :active_payout_profiles, -> { verified.active },
                    class_name: 'Spree::PayoutProfile',
                    through: :payout_profile_shipping_methods, source: :payout_profile

      base.has_many :active_payway_payout_profiles, -> { payway.verified.active },
                    class_name: 'Spree::PayoutProfile',
                    through: :payout_profile_shipping_methods, source: :payout_profile

      base.has_many :required_payout_profile_shipping_methods, -> { required },
                    class_name: 'Spree::PayoutProfileShippingMethod',
                    inverse_of: :shipping_method

      base.has_many :required_active_payout_profiles, -> { verified.active },
                    class_name: 'Spree::PayoutProfile',
                    through: :required_payout_profile_shipping_methods, source: :payout_profile
    end
  end
end

unless Spree::ShippingMethod.included_modules.include?(Vpago::ShippingMethodDecorator)
  Spree::ShippingMethod.prepend(Vpago::ShippingMethodDecorator)
end
