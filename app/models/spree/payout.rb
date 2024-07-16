module Spree
  class Payout < Base
    belongs_to :payout_profile, class_name: 'Spree::PayoutProfile', required: true, inverse_of: :payouts
    belongs_to :line_item, class_name: 'Spree::LineItem', required: false, inverse_of: :payouts
    belongs_to :payment, class_name: 'Spree::Payment', required: true, inverse_of: :payouts

    enum state: { created: 0, confirmed: 1 }

    extend DisplayMoney
    money_methods :amount, :outstanding_amount,
                  :commission_amount,
                  :pre_commission_amount,
                  :subtotal_with_vendor_adjustment_total,
                  :vendor_adjustment_total

    def commission_rate
      private_metadata&.dig('commission_rate')&.to_f
    end

    def commission_amount
      private_metadata&.dig('commission_amount')&.to_f
    end

    def pre_commission_amount
      private_metadata&.dig('pre_commission_amount')&.to_f
    end

    def subtotal_with_vendor_adjustment_total
      private_metadata&.dig('subtotal_with_vendor_adjustment_total')&.to_f
    end

    def vendor_adjustment_total
      private_metadata&.dig('vendor_adjustment_total')&.to_f
    end
  end
end
