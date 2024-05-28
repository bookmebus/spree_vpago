require 'spec_helper'

RSpec.describe Spree::LineItem, type: :model do
  it { should have_many(:payout_profiles).class_name('Spree::PayoutProfile').through(:product) }
  it { should have_many(:required_active_payout_profiles).class_name('Spree::PayoutProfile').through(:product) }

  describe '#commission_rate' do
    let(:vendor) { create(:vendor) }
    let(:product) { create(:product_in_stock, vendor: vendor) }
    let(:line_item) { create(:line_item, product: product) }
  
    context 'when product has a commission rate' do
      it 'returns the product commission rate' do
        allow(product).to receive(:commission_rate).and_return(10)

        expect(line_item.commission_rate).to eq(10)
      end
    end

    # the column:commission_rate is created in spree_cm_commissioner migrations
    # it only defined if both gem install together.
    context 'when product commission_rate is not defined' do
      it 'returns the vendor commission rate' do
        vendor.commission_rate = 15

        expect(line_item.commission_rate).to eq(15)
      end
    end

    context 'when product commission_rate is not defined but nil' do
      it 'returns the vendor commission rate' do
        allow(product).to receive(:commission_rate).and_return(nil)
        vendor.commission_rate = 15

        expect(line_item.commission_rate).to eq(15)
      end
    end

    context 'when neither product nor vendor has a commission rate' do
      it 'returns 0' do
        allow(product).to receive(:commission_rate).and_return(nil)
        vendor.commission_rate = nil

        expect(line_item.commission_rate).to eq(0)
      end
    end
  end

  describe '#commission_amount' do
    let(:vendor) { create(:vendor) }
    let(:product) { create(:product_in_stock, vendor: vendor) }
    let(:line_item) { create(:line_item, product: product, price: 100.0) }

    context 'when product has a commission rate' do
      it 'caculate 10% of 100 base on product commission rate' do
        allow(product).to receive(:commission_rate).and_return(10)

        expect(line_item.commission_amount).to eq(10.0)
      end
    end

    context 'when product does not have a commission rate but vendor does' do
      it 'caculate 15% of 100 base on vendor commission rate' do
        allow(product).to receive(:commission_rate).and_return(nil)
        vendor.commission_rate = 15

        expect(line_item.commission_amount).to eq(15.0)
      end
    end

    context 'when neither product nor vendor has a commission rate' do
      it 'returns 0 as the commission amount' do
        allow(product).to receive(:commission_rate).and_return(nil)
        vendor.commission_rate = nil

        expect(line_item.commission_amount).to eq(0.0)
      end
    end
  end
  
  describe '#pre_commission_amount' do
    let(:vendor) { create(:vendor, commission_rate: 10) }
    let(:product) { create(:product_in_stock, vendor: vendor) }
    let(:line_item) { create(:line_item, product: product, price: 100.0) }

    it 'return amount before commission cut' do
      expect(line_item.commission_amount).to eq 10
      expect(line_item.pre_commission_amount).to eq 90
    end
  end

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