module Vpago
  module LineItemDecorator
    def self.prepended(base)
      base.include ::Vpago::Payoutable

      base.has_many :payout_profiles, class_name: 'Spree::PayoutProfile', through: :product
      base.has_many :active_payout_profiles, class_name: 'Spree::PayoutProfile', through: :product
      base.has_many :active_payway_payout_profiles, class_name: 'Spree::PayoutProfile', through: :product

      base.has_many :required_active_payout_profiles, class_name: 'Spree::PayoutProfile', through: :product

      base.has_one :vendor, through: :variant
      base.has_many :vendor_payment_methods, class_name: 'Spree::PaymentMethod', through: :variant
    end

    # considred required when there are any required profiles.
    def required_payway_payout?
      required_active_payout_profiles.payway.exists?
    end

    def commission_rate
      product_commission_rate = product.respond_to?(:commission_rate) ? product.commission_rate : nil
      product_commission_rate || vendor&.commission_rate || 0
    end

    def commission_amount
      vendor_pre_tax_amount * commission_rate / 100.0
    end

    # amount expected to receive by vendor
    def pre_commission_amount
      vendor_pre_tax_amount - commission_amount + vendor_tax_total
    end

    def vendor_pre_tax_amount
      subtotal + vendor_adjustments_total_excluding_tax
    end

    def vendor_tax_total
      adjustments.tax.handle_by_vendor.total
    end

    def vendor_adjustments_total_excluding_tax
      vendor_adjustment = adjustments.non_tax.handle_by_vendor.total
      order_vendor_adjustment = if order.line_items_count.positive?
                                  order.adjustments.non_tax.handle_by_vendor.total / order.line_items_count
                                else
                                  0
                                end

      order_vendor_adjustment + vendor_adjustment
    end

    def latest_private_metadata
      # Preserve existing metadata and merge with new financial data
      updated_private_metadata = (private_metadata || {}).dup

      updated_private_metadata[:subtotal] = subtotal.to_f
      updated_private_metadata[:commission_rate] = commission_rate.to_f
      updated_private_metadata[:commission_amount] = commission_amount.to_f
      updated_private_metadata[:vendor_pre_tax_amount] = vendor_pre_tax_amount.to_f
      updated_private_metadata[:pre_commission_amount] = pre_commission_amount.to_f
      updated_private_metadata[:vendor_tax_total] = vendor_tax_total.to_f
      updated_private_metadata[:vendor_adjustments_total_excluding_tax] = vendor_adjustments_total_excluding_tax.to_f

      updated_private_metadata
    end

    # generate metadata for financial reports.
    def update_total_metadata
      update_column(:private_metadata, latest_private_metadata)
    end
  end
end

Spree::LineItem.prepend(Vpago::LineItemDecorator) if Spree::LineItem.included_modules.exclude?(Vpago::LineItemDecorator)
