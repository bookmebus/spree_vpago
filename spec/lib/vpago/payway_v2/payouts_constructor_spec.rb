require 'spec_helper'

RSpec.describe Vpago::PaywayV2::PayoutsConstructor do
  let(:payment_method) { create(:payway_v2_gateway) }

  let!(:default_payout_profile) { create(:payway_payout_profile, active: true, bank_account_number: '333', default: true, verified_at: DateTime.current)}
  let(:payout_profile1) { create(:payway_payout_profile, active: true, bank_account_number: '111', verified_at: DateTime.current)}
  let(:payout_profile2) { create(:payway_payout_profile, active: true, bank_account_number: '222', verified_at: DateTime.current)}

  let(:product0) { create(:product_in_stock, payout_profiles: [payout_profile1]) }
  let(:product1) { create(:product_in_stock, payout_profiles: [payout_profile2]) }
  let(:product2) { create(:product_in_stock) }

  let(:line_item0) { create(:line_item, price: 5.0, product: product0) }
  let(:line_item1) { create(:line_item, price: 5.0, product: product1) }
  let(:line_item2) { create(:line_item, price: 11.0, product: product2) }

  let(:order) { create(:order, line_items: [line_item0, line_item1, line_item2]) }
  let!(:payment) { create(:payway_v2_payment, payment_method: payment_method, order: order, amount: 5.0 + 5.0 + 11.0) }

  subject { described_class.new(payment) }

  describe '#call' do
    it 'build_payouts_for_line_items, include_default_payout_for_remaining_amounts, group_payouts, check if payout valid, and format payout' do
      expect(subject).to receive(:build_payouts_for_line_items).and_call_original
      expect(subject).to receive(:include_default_payout_for_remaining_amounts).and_call_original
      expect(subject).to receive(:group_payouts).and_call_original
      expect(subject).to receive(:valid_payout_total?).and_call_original
      expect(subject).to receive(:format_payouts).and_call_original

      subject.call
    end

    it 'return constructed payouts base on payout record from payment' do
      expect(payment.payouts[0].amount).to eq 5.0
      expect(payment.payouts[1].amount).to eq 5.0
      expect(payment.payouts[2].amount).to eq 11.0

      expect(subject.call).to eq([
        {:acc => "111", :amt => "5.00"},
        {:acc => "222", :amt => "5.00"},
        {:acc => "333", :amt => "11.00"}
      ])
    end

    context 'when valid_payout_total = true during .call' do
      it 'return constructed payout' do
        allow(subject).to receive(:valid_payout_total?).and_return(true)

        expect(subject.call).to_not be_empty
      end
    end

    context 'when valid_payout_total = false during .call' do
      it 'return empty payouts, meaning that we still accept payment & deal with this issue later' do
        allow(subject).to receive(:valid_payout_total?).and_return(false)

        expect(subject.call).to be_empty
      end
    end
  end

  describe '#build_payouts_for_line_items' do
    let!(:order) { create(:order, line_items: [line_item0, line_item1, line_item2], payments: [previous_payment, current_payment]) }

    let(:previous_payment) { build(:payway_v2_payment, payment_method: payment_method, amount: 5.0 + 5.0 + 11.0) }
    let(:current_payment) { build(:payway_v2_payment, payment_method: payment_method, amount: 5.0 + 5.0 + 11.0) }

    before do
      Spree::Payout.destroy_all

      create(:payout, payment: previous_payment, amount: 13, line_item: line_item0, payout_profile: payout_profile1)
      create(:payout, payment: current_payment, amount: 17, line_item: line_item0, payout_profile: payout_profile1)
      create(:payout, payment: current_payment, amount: 15, line_item: line_item1, payout_profile: payout_profile2)
    end

    it 'build payouts params base on payout of current_payment' do
      subject = described_class.new(current_payment)

      expect(subject.build_payouts_for_line_items).to eq([
        {:acc => "111", :amt => 17},
        {:acc => "222", :amt => 15}
      ])
    end
  end

  describe '#include_default_payout_for_remaining_amounts' do
    let(:payment) { create(:payment, payment_method: payment_method, order: order, amount: 5.0 + 5.0 + 11.0 + remaining_amount)}

    context 'when there are remaining amount' do
      let(:remaining_amount) { 30 }

      it 'add remaining amount with default account to existing payout' do
        result = subject.include_default_payout_for_remaining_amounts([
          {:acc => "111", :amt => 5.0},
          {:acc => "111", :amt => 5.0},
          {:acc => "222", :amt => 11.0}
        ])

        expect(result).to eq([
          {:acc => "111", :amt => 5.0},
          {:acc => "111", :amt => 5.0},
          {:acc => "222", :amt => 11.0},
          {:acc => default_payout_profile.bank_account_number, :amt => remaining_amount},
        ])
      end
    end

    context 'when there are no remaining amount' do
      let(:remaining_amount) { 0 }

      it 'does not change anything' do
        result = subject.include_default_payout_for_remaining_amounts([
          {:acc => "111", :amt => 5.0},
          {:acc => "111", :amt => 5.0},
          {:acc => "222", :amt => 11.0}
        ])

        expect(result).to eq([
          {:acc => "111", :amt => 5.0},
          {:acc => "111", :amt => 5.0},
          {:acc => "222", :amt => 11.0}
        ])
      end
    end
  end

  describe '#valid_payout_total?' do
    context 'when sum of payout != payment amount' do
      let(:payment) { create(:payment, payment_method: payment_method, order: order, amount: 10) }
      let(:payouts) { [ { acc: "111", amt: 12 } ]}

      it 'return false' do
        expect(subject.valid_payout_total?(payouts)).to be false
      end
    end

    context 'when sum of payout == payment amount' do
      let(:payment) { create(:payment, payment_method: payment_method, order: order, amount: 10) }
      let(:payouts) { [ { acc: "111", amt: 10 } ]}

      it 'return true' do
        expect(subject.valid_payout_total?(payouts)).to be true
      end
    end
  end

  describe '#group_payouts' do
    it 'group by account & sum by amount' do
      payouts = [ 
        { acc: '111', amt: 10 }, { acc: '111', amt: 11 },
        { acc: '222', amt: 12 }, { acc: '222', amt: 8 },
        { acc: '333', amt: 14 }
      ]

      expect(subject.group_payouts(payouts)).to eq([
        { acc: "111", amt: 10 + 11 },
        { acc: "222", amt: 12 + 8 },
        { acc: "333", amt: 14 }
      ])
    end
  end

  describe '#format_payouts' do
    it 'format payout amount' do
      payouts = [ 
        { acc: "111", amt: 21 },
        { acc: "222", amt: 20 },
        { acc: "333", amt: 14 }
      ]

      expect(subject.format_payouts(payouts)).to eq([
        { acc: "111", amt: "21.00" },
        { acc: "222", amt: "20.00" },
        { acc: "333", amt: "14.00" }
      ])
    end
  end
end