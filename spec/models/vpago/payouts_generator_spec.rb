require 'spec_helper'

RSpec.describe Vpago::PayoutsGenerator do
  let!(:default_payout_profile) { create(:payway_payout_profile, active: true, bank_account_number: '333', default: true, verified_at: DateTime.current)}

  let!(:default_payout_profile) { create(:payway_payout_profile, active: true, bank_account_number: '333', default: true, verified_at: DateTime.current)}
  let(:payout_profile1) { create(:payway_payout_profile, active: true, bank_account_number: '111', verified_at: DateTime.current)}
  let(:payout_profile2) { create(:payway_payout_profile, active: true, bank_account_number: '222', verified_at: DateTime.current)}
  let(:payout_profile3) { create(:payway_payout_profile, active: true, bank_account_number: '444', verified_at: DateTime.current)}

  let(:product0) { create(:product_in_stock, payout_profiles: [payout_profile1]) }
  let(:product1) { create(:product_in_stock, payout_profiles: [payout_profile2]) }
  let(:product2) { create(:product_in_stock) }

  let(:line_item0) { create(:line_item, price: 5.0, product: product0) }
  let(:line_item1) { create(:line_item, price: 6.0, product: product1) }
  let(:line_item2) { create(:line_item, price: 11.0, product: product2) }

  let(:order) { create(:order_with_line_items, shipment_cost: 20, line_items: [line_item0, line_item1, line_item2], without_line_items: true) }
  let(:shipment) { order.shipments.first }

  let!(:shipping_method) do
    shipping_method = shipment.shipping_method
    shipping_method.handle_by = :vendor
    shipping_method.payout_profiles = [payout_profile3]
    shipping_method.save
    shipping_method
  end

  let!(:shipping_rate) do
    shipping_rate = shipment.selected_shipping_rate
    shipping_rate.handle_by = :vendor
    shipping_rate.save
    shipping_rate
  end

  let!(:payment) { create(:payway_v2_payment, order: order, amount: 5.0 + 6.0 + 11.0 + order.shipment_total) }

  before do
    # payment auto generate payout, we have to remove it for manully create them again for test.
    Spree::Payout.destroy_all
  end

  subject { described_class.new(payment) }

  describe '#call' do
    it 'generates and saves payouts combine of vendor_payouts, vendor_shipment_payouts & store_payouts' do
      expect(subject).to receive(:vendor_payouts).and_call_original
      expect(subject).to receive(:vendor_shipment_payouts).and_call_original
      expect(subject).to receive(:store_payouts).and_call_original

      payouts = subject.call

      expect(payouts.size).to eq 4

      expect(payouts[0].amount).to eq 5.0
      expect(payouts[0].payoutable).to eq line_item0
      expect(payouts[0].payout_profile).to eq payout_profile1

      expect(payouts[1].amount).to eq 6.0
      expect(payouts[1].payoutable).to eq line_item1
      expect(payouts[1].payout_profile).to eq payout_profile2

      expect(payouts[2].amount).to eq order.shipment_total
      expect(payouts[2].payoutable).to eq shipment
      expect(payouts[2].payout_profile).to eq payout_profile3

      expect(payouts[3].amount).to eq 11.0
      expect(payouts[3].payoutable).to eq nil
      expect(payouts[3].payout_profile).to eq default_payout_profile
    end
  end

  describe '#vendor_payouts' do
    context 'when does not have confirmed_payouts before in previous payments' do
      before do
        # payment auto generate payout, we have to remove it for manully create them again for test.
        Spree::Payout.destroy_all
      end

      it 'only build payouts for line item with associated payout_profiles' do
        vendor_payouts = subject.vendor_payouts

        expect(vendor_payouts.size).to eq 2

        expect(line_item0.payout_profiles.size).to eq 1
        expect(vendor_payouts[0].payoutable).to eq line_item0
        expect(vendor_payouts[0].amount).to eq(5.0)

        expect(line_item1.payout_profiles.size).to eq 1
        expect(vendor_payouts[1].payoutable).to eq line_item1
        expect(vendor_payouts[1].amount).to eq(6.0)

        # line_item_2 does not have payout profiles, so we don't build them in vendor_payouts.
        expect(line_item2.payout_profiles.size).to eq 0
        expect(vendor_payouts[2]).to be nil
      end
    end

    context 'when have confirmed_payouts in previous payments' do
      before do
        # payment auto generate payout, we have to remove it for manully create them again for test.
        Spree::Payout.destroy_all

        create(:payout, state: :confirmed, amount: 1, payoutable: line_item0)
        create(:payout, state: :confirmed, amount: 2, payoutable: line_item1)
      end

      it 'build vendor payouts with only amount that remain from previous payouts' do
        vendor_payouts = subject.vendor_payouts

        expect(vendor_payouts.size).to eq 2
        expect(vendor_payouts[0].id).to eq nil
        expect(vendor_payouts[0].payoutable).to eq line_item0
        expect(vendor_payouts[0].amount).to eq(5.0 - 1)

        expect(vendor_payouts[1].payoutable).to eq line_item1
        expect(vendor_payouts[1].amount).to eq(6.0 - 2)
      end
    end
  end

  describe '#vendor_shipment_payouts' do
    context 'when does not have confirmed_payouts for shipment in previous payments' do
      before do
        # payment auto generate payout, we have to remove it for manully create them again for test.
        Spree::Payout.destroy_all
      end

      it 'build payouts for all required amount' do
        vendor_shipment_payouts = subject.vendor_shipment_payouts

        expect(vendor_shipment_payouts.size).to eq 1
        expect(vendor_shipment_payouts[0].id).to eq nil
        expect(vendor_shipment_payouts[0].payout_profile).to eq payout_profile3
        expect(vendor_shipment_payouts[0].payoutable).to eq shipment

        expect(shipment.cost).to eq 20
        expect(vendor_shipment_payouts[0].amount).to eq 20
      end
    end

    context 'when have confirmed_payouts in previous payments' do
      before do
        # payment auto generate payout, we have to remove it for manully create them again for test.
        Spree::Payout.destroy_all

        create(:payout, state: :confirmed, amount: 3, payoutable: shipment)
      end

      it 'build payouts with only amount that remain from previous payouts' do
        vendor_shipment_payouts = subject.vendor_shipment_payouts

        expect(vendor_shipment_payouts.size).to eq 1
        expect(vendor_shipment_payouts[0].id).to eq nil
        expect(vendor_shipment_payouts[0].payout_profile).to eq payout_profile3
        expect(vendor_shipment_payouts[0].payoutable).to eq shipment
        expect(vendor_shipment_payouts[0].amount).to eq shipment.cost - 3
      end
    end
  end

  describe '#store_payouts' do
    it 'build payouts for all remaining amount' do
      expect(subject.remaining_amount).to eq payment.amount
      expect(subject.store_payouts.size).to eq 1

      expect(subject.store_payouts[0].amount).to eq payment.amount
      expect(subject.store_payouts[0].state).to eq 'created'
      expect(subject.store_payouts[0].payout_profile).to eq Spree::PayoutProfiles::PaywayV2.default
    end
  end
end
