module Vpago
  module InventoryUnitDecorator
    def self.prepended(base)
      base.has_one :selected_shipping_rate, through: :shipment, class_name: 'Spree::ShippingRate'
    end
  end
end

unless Spree::InventoryUnit.included_modules.include?(Vpago::InventoryUnitDecorator)
  Spree::InventoryUnit.prepend(Vpago::InventoryUnitDecorator)
end
