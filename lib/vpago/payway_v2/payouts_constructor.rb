module Vpago
  module PaywayV2
    class PayoutsConstructor
      attr_reader :payment, :line_items

      def initialize(payment)
        @payment = payment
        @line_items = @payment.order.line_items.includes(payouts: :payout_profile)
      end

      def call
        payouts = build_payouts_from_payment
        payouts = group_payouts(payouts)

        format_payouts(payouts)
      end

      def build_payouts_from_payment
        payment.payouts.each_with_object([]) do |payout, payouts|
          payouts << {
            acc: payout.payout_profile.bank_account_number,
            amt: payout.amount
          }
        end
      end

      # group & sum amount by acc number.
      def group_payouts(payouts)
        payouts.group_by { |item| item[:acc] }.map do |acc, items|
          {
            acc: acc,
            amt: items.sum { |item| item[:amt] }
          }
        end
      end

      def format_payouts(payouts)
        payouts.map do |payout|
          {
            acc: payout[:acc],
            amt: "%.2f" % payout[:amt]
          }
        end
      end
    end
  end
end
