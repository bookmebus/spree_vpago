module Vpago
  class PayoutsGenerator
    attr_reader :payment, :line_items

    attr_accessor :remaining_amount

    def initialize(payment)
      @payment = payment
      @line_items = payment.order.line_items.includes(:active_payway_payout_profiles, :confirmed_payouts, :adjustments)
      @remaining_amount = payment.amount
    end

    def call
      payouts = build_payout_line_items_for_send_to_vendor
      payouts += build_remaining_payouts_for_send_to_store
      payouts.save! if valid_payout_total?(payouts)
    end

    def valid_payout_total?(payouts)
      payment.amount == payouts.sum(&:amount)
    end

    def build_payout_line_items_for_send_to_vendor
      line_items.each_with_object([]) do |line_item, payouts|
        next if remaining_amount <= 0

        payout_profile = line_item.active_payway_payout_profiles.first
        next unless payout_profile.present?

        total_confirmed_payouts = line_item.confirmed_payouts.sum(:amount)
        next if total_confirmed_payouts >= line_item.pre_commission_amount

        amount_owed_to_vendor = line_item.pre_commission_amount - payout_total
        payout_amount = [amount_owed_to_vendor, remaining_amount].min

        payouts << Spree::Payout.new(
          payoutable: line_item,
          state: :created,
          payment: payment,
          payout_profile: payout_profile,
          amount: payout_amount,
        )

        self.remaining_amount -= payout_amount
      end
    end

    def build_remaining_payouts_for_send_to_store
      return if remaining_amount <= 0

      payout_profile = Spree::PayoutProfiles::PaywayV2.default
      payouts = []
      payouts = Spree::Payout.new(
        state: :created,
        payment: payment,
        payout_profile: payout_profile,
        amount: amount_can_be_send,
      )

      payouts
    end
  end
end
