require 'spec_helper'

RSpec.describe Spree::LineItem, type: :model do
  it { should have_many(:payout_profiles).class_name('Spree::PayoutProfile').through(:product) }
  it { should have_many(:required_active_payout_profiles).class_name('Spree::PayoutProfile').through(:product) }

  describe '#required_payway_payout?' do
    context 'when there are required_active_payout_profiles in product' do
      let(:payout_product) { build(:payway_payout_profile, active: true, verified_at: DateTime.current)}
      let(:product) { create(:product, required_active_payout_profiles: [payout_product]) }
      let(:line_item) { create(:line_item, product: product) }

      it 'return true' do
        expect(product.required_active_payout_profiles.payway.exists?).to be true
        expect(line_item.required_active_payout_profiles.payway.exists?).to be true

        expect(line_item.required_payway_payout?).to be true
      end
    end

    context 'when there are no required_active_payout_profiles in product' do
      let(:product) { create(:product, required_active_payout_profiles: []) }
      let(:line_item) { create(:line_item, product: product) }

      it 'return false' do
        expect(product.required_active_payout_profiles.payway.exists?).to be false
        expect(line_item.required_active_payout_profiles.payway.exists?).to be false

        expect(line_item.required_payway_payout?).to be false
      end
    end
  end
end