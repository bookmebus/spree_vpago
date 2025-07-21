module Vpago
  module VendorDecorator
    def self.prepended(base)
      base.has_many :payout_profiles, class_name: 'Spree::PayoutProfile', inverse_of: :vendor
    end
  end
end

Spree::Vendor.prepend(Vpago::VendorDecorator) unless Spree::Vendor.included_modules.include?(Vpago::VendorDecorator)
