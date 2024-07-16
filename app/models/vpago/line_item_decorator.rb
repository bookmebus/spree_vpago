module Vpago
  module LineItemDecorator
    def self.prepended(base)
      base.has_many :payouts, class_name: 'Spree::Payout'
      base.has_many :confirmed_payouts_for_vendor, -> { confirmed.where(default: false) },
                    class_name: 'Spree::Payout'

      base.has_many :payout_profiles, class_name: 'Spree::PayoutProfile', through: :product
      base.has_many :active_payout_profiles, class_name: 'Spree::PayoutProfile', through: :product
      base.has_many :active_payway_payout_profiles, class_name: 'Spree::PayoutProfile', through: :product

      base.has_many :required_active_payout_profiles, class_name: 'Spree::PayoutProfile', through: :product
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
      pre_tax_amount * commission_rate / 100.0
    end

    def pre_commission_amount
      pre_tax_amount - commission_amount
    end
  end
end

Spree::LineItem.prepend(Vpago::LineItemDecorator)
