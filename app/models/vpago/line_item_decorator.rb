module Vpago
  module LineItemDecorator
    def self.prepended(base)
      base.has_many :payouts, class_name: 'Spree::Payout', inverse_of: :line_item
      base.has_many :confirmed_payouts, -> { confirmed }, class_name: 'Spree::Payout', inverse_of: :line_item

      base.has_many :payout_profiles, class_name: 'Spree::PayoutProfile', through: :product
      base.has_many :active_payout_profiles, class_name: 'Spree::PayoutProfile', through: :product
      base.has_many :active_payway_payout_profiles, class_name: 'Spree::PayoutProfile', through: :product

      base.has_many :required_active_payout_profiles, class_name: 'Spree::PayoutProfile', through: :product

      base.has_many :shipments, class_name: 'Spree::Shipment', through: :inventory_units
      base.has_many :selected_shipping_rates, class_name: 'Spree::ShippingRate', through: :inventory_units
    end

    # considred required when there are any required profiles.
    def required_payway_payout?
      required_active_payout_profiles.payway.exists?
    end

    def commission_rate
      product_commission_rate = product.respond_to?(:commission_rate) ? product.commission_rate : nil
      product_commission_rate || vendor&.commission_rate ||  0
    end

    def commission_amount
      subtotal_with_vendor_adjustment_total * commission_rate / 100.0
    end

    def pre_commission_amount
      subtotal_with_vendor_adjustment_total - commission_amount
    end

    # using subtotal instead of pre_tax_amount since pre_tax_amount already include adjustments amount in it.
    # we want raw amount to add only vendor adjustment amount.
    def subtotal_with_vendor_adjustment_total
      subtotal + vendor_adjustment_total
    end

    def vendor_adjustment_total
      @vendor_adjustment_total ||= begin
        order_adjustment = order.line_items_count.zero? ? 0 : order.adjustments.handle_by_vendor.total / order.line_items_count
        adjustments.handle_by_vendor.total + order_adjustment
      end
    end
  end
end

Spree::LineItem.prepend(Vpago::LineItemDecorator)
