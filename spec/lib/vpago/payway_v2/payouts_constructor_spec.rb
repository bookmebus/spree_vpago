require 'spec_helper'

RSpec.describe Vpago::PaywayV2::PayoutsConstructor do
  let(:payment_method) { create(:payway_v2_gateway) }

  let!(:default_payout_profile) { create(:payway_payout_profile, active: true, bank_account_number: '333', default: true, verified_at: DateTime.current)}
  let(:payout_profile1) { create(:payway_payout_profile, active: true, bank_account_number: '111', verified_at: DateTime.current)}
  let(:payout_profile2) { create(:payway_payout_profile, active: true, bank_account_number: '222', verified_at: DateTime.current)}

  let(:product0) { create(:product, payout_profiles: [payout_profile1]) }
  let(:product1) { create(:product, payout_profiles: [payout_profile1]) }
  let(:product2) { create(:product, payout_profiles: [payout_profile2]) }

  let(:payout_line_item0) { create(:line_item, product: product0, price: 5.0) }
  let(:payout_line_item1) { create(:line_item, product: product1, price: 5.0) }
  let(:payout_line_item2) { create(:line_item, product: product2, price: 11.0) }
  let(:no_payout_line_item) { create(:line_item, price: 12.0) }

  let(:order) { create(:order, line_items: [payout_line_item0, payout_line_item1, payout_line_item2, no_payout_line_item]) }

  let(:payment) { create(:payment, payment_method: payment_method, order: order, amount: 5.0 + 5.0 + 11 + 12)}

  subject { described_class.new(payment) }

  describe '#call' do
    context 'when allowed_payout? is false' do
      it 'return empty payouts' do
        allow(order).to receive(:allowed_payout?).and_return(false)

        expect(subject.call).to eq([])
      end
    end

    context 'when allowed_payout? is true' do
      it 'constuct payouts for all 4 line items, add default payout for remaining amount, and group them' do
        expect(order.allowed_payout?).to be true
        expect(subject.call).to eq([
          { acc: payout_profile1.bank_account_number, amt: '10.00' }, # 5$ + 5$ | line_item_0 + line_item_1
          { acc: payout_profile2.bank_account_number, amt: '11.00' },
          { acc: default_payout_profile.bank_account_number, amt: '12.00' },
        ])
      end
    end
  end

  describe '#build_payouts_for_line_items' do
    it 'return payout for all 4 line items' do
      expect(subject.build_payouts_for_line_items).to eq([
        { acc: payout_profile1.bank_account_number, amt: 5.0 },
        { acc: payout_profile1.bank_account_number, amt: 5.0 },
        { acc: payout_profile2.bank_account_number, amt: 11.0 }
      ])
    end
  end

  describe '#include_default_payout_for_remaining_amounts' do
    let(:payment) { create(:payment, payment_method: payment_method, order: order, amount: 10.0 + 11.0 + 12.0)}

    context 'when has remaing amount' do
      it 'return construct default payout for remaining amount 12.0' do
        payouts = subject.build_payouts_for_line_items
  
        expect(subject.include_default_payout_for_remaining_amounts(payouts)).to eq([
          { acc: payout_profile1.bank_account_number, amt: 5.0 },
          { acc: payout_profile1.bank_account_number, amt: 5.0 },
          { acc: payout_profile2.bank_account_number, amt: 11.0 },
          { acc: default_payout_profile.bank_account_number, amt: 12.0 },
        ])
      end
    end

    context 'when has NO remaing amount' do
      # override
      let(:payment) { create(:payment, payment_method: payment_method, order: order, amount: 10.0 + 11.0)}

      it 'return does not return with default payout profile' do
        payouts = subject.build_payouts_for_line_items
  
        expect(subject.include_default_payout_for_remaining_amounts(payouts)).to eq([
          { acc: payout_profile1.bank_account_number, amt: 5.0 },
          { acc: payout_profile1.bank_account_number, amt: 5.0 },
          { acc: payout_profile2.bank_account_number, amt: 11.0 },
        ])
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
        { acc: "111", amt: "21.00" },
        { acc: "222", amt: "20.00" },
        { acc: "333", amt: "14.00" }
      ])
    end
  end

  describe '#format_amount' do
    it 'formats the amount with two decimal places' do
      formatted_amount = subject.format_amount(123.456)
      expect(formatted_amount).to eq '123.46'
    end

    it 'formats the amount correctly when it is an integer' do
      formatted_amount = subject.format_amount(100)
      expect(formatted_amount).to eq '100.00'
    end

    it 'formats the amount correctly when it has one decimal place' do
      formatted_amount = subject.format_amount(55.5)
      expect(formatted_amount).to eq '55.50'
    end

    it 'formats the amount correctly when it is zero' do
      formatted_amount = subject.format_amount(0)
      expect(formatted_amount).to eq '0.00'
    end
  end
end