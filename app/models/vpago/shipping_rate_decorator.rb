module Vpago
  module ShippingRateDecorator
    def self.prepended(base)
      base.enum handle_by: { unspecified: 0, store: 1, vendor: 2 }, _prefix: true

      base.scope :handle_by_vendor, -> { where(handle_by: :vendor) }
      base.scope :handle_by_store, -> { where(handle_by: :store) }

      base.before_save :set_handle_by
    end

    private

    def set_handle_by
      self.handle_by = shipping_method.handle_by
    end
  end
end

unless Spree::ShippingRate.included_modules.include?(Vpago::ShippingRateDecorator)
  Spree::ShippingRate.prepend(Vpago::ShippingRateDecorator)
end
