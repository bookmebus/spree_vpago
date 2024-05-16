require 'spec_helper'

RSpec.describe Spree::LineItem, type: :model do
  it { should have_many(:payout_profiles).class_name('Spree::PayoutProfile').through(:product) }

  describe '#required_payway_payout?' do
    let(:payout_profiles) { [payout_product] }
    let(:product) { create(:product, payout_profiles: payout_profiles) }
    let(:line_item) { create(:line_item, product: product) }

    context 'when have active & verified payout profile in product' do
      let(:payout_product) { create(:payway_payout_profile, active: true, verified_at: DateTime.current)}
  
      it 'return true' do
        expect(line_item.active_payway_payout_profiles).to eq [payout_product]
        expect(line_item.required_payway_payout?).to be true
      end
    end

    context 'when have verified, but not active payout profile in product' do
      let(:payout_product) { create(:payway_payout_profile, active: false, verified_at: DateTime.current)}
  
      it 'return false' do
        expect(line_item.active_payway_payout_profiles).to eq []
        expect(line_item.required_payway_payout?).to be false
      end
    end

    context 'when have active, but not verified payout profile in product' do
      let(:payout_product) { create(:payway_payout_profile, active: false, verified_at: DateTime.current)}
  
      it 'return false' do
        expect(line_item.active_payway_payout_profiles).to eq []
        expect(line_item.required_payway_payout?).to be false
      end
    end

    context 'when does not have active & verified payout profile in product' do
      let(:payout_profiles) { [] }
  
      it 'return false' do
        expect(line_item.active_payway_payout_profiles).to eq []
        expect(line_item.required_payway_payout?).to be false
      end
    end
  end
end