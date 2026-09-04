require 'spec_helper'

RSpec.describe Vpago::PaywayV2::PayoutsParamsConstructor do
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
    it 'constuct payouts for all 4 line items, add default payout for remaining amount, and group them' do
      expect(subject).to receive(:build_payouts_from_payment).and_call_original
      expect(subject).to receive(:group_payouts).and_call_original
      expect(subject).to receive(:format_payouts).and_call_original

      expect(subject.call).to match_array([
        { acc: payout_profile1.bank_account_number, amt: '10.00' }, # combine of line_item_0 5$ + line_item_1 5$
        { acc: payout_profile2.bank_account_number, amt: '11.00' },
        { acc: default_payout_profile.bank_account_number, amt: '12.00' },
      ])
    end
  end
end
