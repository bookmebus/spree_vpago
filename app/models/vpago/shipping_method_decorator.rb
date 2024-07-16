module Vpago
  module ShippingMethodDecorator
    def self.prepended(base)
      base.enum handle_by: { unspecified: 0, store: 1, vendor: 2 }, _prefix: true
    end
  end
end

unless Spree::ShippingMethod.included_modules.include?(Vpago::ShippingMethodDecorator)
  Spree::ShippingMethod.prepend(Vpago::ShippingMethodDecorator)
end
