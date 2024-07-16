# generate payouts for remaining amount of provided payment.
module Vpago
  class PayoutsGenerator
    attr_reader :payment, :line_items

    attr_accessor :remaining_amount

    def initialize(payment)
      @payment = payment
      @line_items = payment.order.line_items.includes(
        :active_payway_payout_profiles,
        :confirmed_payouts_for_vendor,
        :adjustments
      )

      self.remaining_amount = payment.amount
    end

    def call
      payouts = vendor_payouts + store_payouts

      ActiveRecord::Base.transaction { payouts.each(&:save!) }
    end

    def vendor_payouts
      line_items.each_with_object([]) do |line_item, payouts|
        payout_profile = line_item.active_payway_payout_profiles.first
        next unless payout_profile.present?

        total_confirmed_payouts = line_item.confirmed_payouts_for_vendor.sum(:amount)
        next if total_confirmed_payouts >= line_item.pre_commission_amount

        amount_owed_to_vendor = line_item.pre_commission_amount - total_confirmed_payouts
        payout_amount = [amount_owed_to_vendor, remaining_amount].min
        outstanding_amount = [amount_owed_to_vendor - payout_amount, 0].max

        payouts << Spree::Payout.new(
          default: false,
          state: :created,
          line_item: line_item,
          payment: payment,
          payout_profile: payout_profile,
          currency: payment.currency,
          amount: payout_amount,
          outstanding_amount: outstanding_amount,
          private_metadata: line_item.private_metadata
        )

        self.remaining_amount -= payout_amount
      end
    end

    # generate payout for all remaining amount to store.
    def store_payouts
      return [] if self.remaining_amount <= 0

      [
        Spree::Payout.new(
          default: true,
          state: :created,
          payment: payment,
          payout_profile: Spree::PayoutProfiles::PaywayV2.default,
          currency: payment.currency,
          amount: self.remaining_amount
        )
      ]
    end
  end
end
