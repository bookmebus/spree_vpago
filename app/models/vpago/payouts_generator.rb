# generate payouts for remaining amount of provided payment.
# currently only support for PaywayV2 payment.
module Vpago
  class PayoutsGenerator
    attr_reader :payment, :line_items, :shipments

    attr_accessor :remaining_amount

    def initialize(payment)
      @payment = payment

      @line_items = payment.order.line_items.includes(
        :active_payway_payout_profiles,
        :confirmed_payouts_for_vendor,
        :adjustments
      )

      @shipments = payment.order.shipments.includes(
        :confirmed_payouts_for_vendor,
        :adjustments,
        selected_shipping_rate: :active_payway_payout_profiles
      )

      self.remaining_amount = payment.amount
    end

    def call
      payouts = vendor_payouts + vendor_shipment_payouts + store_payouts
      payouts = payouts.map do |payout|
        payout.amount = round_up(payout.amount)
        payout
      end

      return [] if payouts.all?(&:default?)
      return [] unless payouts.all? { |payout| validated?(payout) }

      ActiveRecord::Base.transaction do
        payouts.each(&:save!)

        # If any payouts were rounded, the total may increase slightly.
        # Update the payment amount to match the sum of payouts to avoid mismatch errors.
        payment.update(amount: payouts.map(&:amount).sum, preload_payout_ids: payouts.map(&:id))

        payouts
      end
    end

    def validated?(payout)
      return false if payout.payout_profile.preferred_merchant_id != payment.payment_method.preferred_merchant_id

      true
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
          payoutable: line_item,
          payment: payment,
          payout_profile: payout_profile,
          amount: payout_amount,
          outstanding_amount: outstanding_amount,
          private_metadata: {
            total_confirmed_payouts: total_confirmed_payouts,
            amount_owed_to_vendor: amount_owed_to_vendor,
            payoutable: line_item.latest_private_metadata
          }
        )

        self.remaining_amount -= payout_amount
      end
    end

    def vendor_shipment_payouts
      shipments.each_with_object([]) do |shipment, payouts|
        next unless shipment.selected_shipping_rate.handle_by_vendor?

        payout_profile = shipment.selected_shipping_rate.active_payway_payout_profiles.first
        next unless payout_profile.present?

        total_confirmed_payouts = shipment.confirmed_payouts_for_vendor.sum(:amount)
        next if total_confirmed_payouts >= shipment.cost_with_vendor_adjustment_total

        amount_owed_to_shipping_vendor = shipment.cost_with_vendor_adjustment_total - total_confirmed_payouts
        payout_amount = [amount_owed_to_shipping_vendor, remaining_amount].min
        outstanding_amount = [amount_owed_to_shipping_vendor - payout_amount, 0].max

        payouts << Spree::Payout.new(
          default: false,
          state: :created,
          payoutable: shipment,
          payment: payment,
          payout_profile: payout_profile,
          amount: payout_amount,
          outstanding_amount: outstanding_amount,
          private_metadata: {
            total_confirmed_payouts: total_confirmed_payouts,
            amount_owed_to_vendor: amount_owed_to_shipping_vendor,
            payoutable: {
              cost: shipment.cost,
              vendor_adjustment_total: shipment.vendor_adjustment_total,
              cost_with_vendor_adjustment_total: shipment.cost_with_vendor_adjustment_total
            }
          }
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
          amount: self.remaining_amount
        )
      ]
    end

    # ABA does not support amounts with more than 2 decimal places.
    # Therefore, we must round all 3-decimal payouts to 2 decimals beforehand.
    #
    # Example:
    # Total amount: $2.5
    #
    # - Vendor 1: $0.625 → $0.63
    # - Vendor 2: $0.625 → $0.63
    # - Platform: $1.25
    #
    # Final amount: 2.51$
    def round_up(amount)
      (amount * 100).ceil / 100.0
    end
  end
end
