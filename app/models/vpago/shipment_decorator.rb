module Vpago
  module ShipmentDecorator
    def self.prepended(base)
      base.include ::Vpago::Payoutable
    end

    def required_payway_payout?
      selected_shipping_rate.required_active_payout_profiles.payway.exists?
    end

    # there is no commission for shipment yet.
    # so amount that vendor expected is cost + their adjustments.
    def cost_with_vendor_adjustment_total
      cost + vendor_adjustment_total
    end

    def vendor_adjustment_total
      adjustments.handle_by_vendor.total
    end
  end
end

unless Spree::Shipment.included_modules.include?(Vpago::ShipmentDecorator)
  Spree::Shipment.prepend(Vpago::ShipmentDecorator)
end
