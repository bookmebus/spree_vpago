# Construct payout profiles and amounts for each line item.
# 
# Currently, we send the total amount of each line item to select a payout profile if available.
# Any remaining amount from line items without a payout profile will be sent to the default account.
# 
# Remaining amount also include commission & shipment amount which of course send to default account.
module Vpago
  module PaywayV2
    class PayoutsConstructor
      attr_reader :payment, :line_items

      def initialize(payment)
        @payment = payment
        @line_items = @payment.order.line_items.includes(:active_payway_payout_profiles)
      end

      def call
        return [] unless @payment.order.allowed_payout?

        payouts = build_payouts_for_line_items
        payouts = include_default_payout_for_remaining_amounts(payouts)
        payouts = group_payouts(payouts)

        payouts
      end

      # construct payouts for line item product that has payout profile.
      def build_payouts_for_line_items
        line_items.each_with_object([]) do |line_item, payouts|
          payout_profile = line_item.active_payway_payout_profiles.first

          if payout_profile.present?
            payouts << { acc: payout_profile.bank_account_number, amt: line_item.pre_commission_amount }
          end
        end
      end

      def include_default_payout_for_remaining_amounts(payouts)
        payout_amount = payouts.sum { |payout| payout[:amt] }
        remaining_amount = payment.amount - payout_amount

        # send remaing amount to default account.
        if payouts.any? && remaining_amount > 0
          default_payout_account = Spree::PayoutProfiles::PaywayV2.default.bank_account_number
          payouts << { acc: default_payout_account, amt: remaining_amount }
        end

        payouts
      end

      # group & sum amount by acc number.
      def group_payouts(payouts)
        payouts.group_by { |item| item[:acc] }.map do |acc, items|
          {
            acc: acc,
            amt: format_amount(items.sum { |item| item[:amt] })
          }
        end
      end

      def format_amount(amount)
        "%.2f" % amount
      end
    end
  end
end