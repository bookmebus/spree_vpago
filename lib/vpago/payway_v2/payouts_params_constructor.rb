module Vpago
  module PaywayV2
    class PayoutsParamsConstructor
      attr_reader :payment, :payouts

      def initialize(payment)
        @payment = payment
        @payouts = payment.payouts.includes(:payout_profile)
      end

      def call
        payouts = build_payouts_from_payment
        payouts = group_payouts(payouts)

        format_payouts(payouts)
      end

      def build_payouts_from_payment
        payouts.each_with_object([]) do |payout, payouts_hash|
          payouts_hash << {
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
            amt: format('%.2f', payout[:amt])
          }
        end
      end
    end
  end
end
