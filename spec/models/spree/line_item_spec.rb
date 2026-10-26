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
    let(:line_item) { create(:line_item) }

    it 'return subtotal_with_vendor_adjustment_total * commission / 100' do
      allow(line_item).to receive(:vendor_pre_tax_amount).and_return(70)
      allow(line_item).to receive(:commission_rate).and_return(10)

      expect(line_item.commission_amount).to eq(70.0 * 10.0 / 100)
    end
  end

  describe '#pre_commission_amount' do
    let(:line_item) { create(:line_item) }

    it 'return subtotal_with_vendor_adjustment_total - commission_amount + vendor_tax_total' do
      allow(line_item).to receive(:vendor_pre_tax_amount).and_return(30)
      allow(line_item).to receive(:commission_amount).and_return(20)
      allow(line_item).to receive(:vendor_tax_total).and_return(3)

      expect(line_item.pre_commission_amount).to eq(30 - 20 + 3)
    end
  end

  describe '#vendor_pre_tax_amount' do
    let(:line_item) { create(:line_item) }

    it 'return subtotal + vendor_adjustments_total_excluding_tax' do
      allow(line_item).to receive(:subtotal).and_return(50)
      allow(line_item).to receive(:vendor_adjustments_total_excluding_tax).and_return(30)

      expect(line_item.pre_commission_amount).to eq(50 + 30)
    end
  end

  describe '#vendor_adjustments_total_excluding_tax' do
    let(:line_item1) { create(:line_item, price: 50) }
    let(:line_item2) { create(:line_item, price: 50) }

    let!(:order) { create(:order, line_items: [line_item1, line_item2], state: :cart) }

    let(:line_item_promotion_by_vendor_26) { create(:promotion_with_item_adjustment, adjustment_rate: 26) }
    let(:line_item_promotion_by_store_27) { create(:promotion_with_item_adjustment, adjustment_rate: 27) }

    let(:order_promotion_by_vendor_13) { create(:promotion_with_order_adjustment, weighted_order_adjustment_amount: 13) }
    let(:order_promotion_by_store_14) { create(:promotion_with_order_adjustment, weighted_order_adjustment_amount: 14) }

    before do
      order.update_with_updater!

      promotions_run_by_vendor.each { |promotion| promotion.actions.update_all(run_by: :vendor) && promotion.activate(order: order) }
      promotions_run_by_store.each { |promotion| promotion.actions.update_all(run_by: :store) && promotion.activate(order: order) }

      # make it eligible
      line_item1.adjustments.update_all(eligible: true)
      order.adjustments.update_all(eligible: true)
    end

    context 'when there is promotion that run by vendor' do
      let(:promotions_run_by_vendor) { [line_item_promotion_by_vendor_26, order_promotion_by_vendor_13] }
      let(:promotions_run_by_store) { [] }
  
      it 'return line item adjustments + order adjustments (order adjustments split to 2 because there are 2 line items)' do
        expect(line_item1.vendor_adjustments_total_excluding_tax).to eq(-26 - 13.0 / 2)
      end
    end

    context 'when there are promotions that run by both vendor & store' do    
      let(:promotions_run_by_vendor) { [line_item_promotion_by_vendor_26, order_promotion_by_vendor_13] }
      let(:promotions_run_by_store) { [line_item_promotion_by_store_27, order_promotion_by_store_14] }

      it 'only return line items & order adjustment that run by store' do
        expect(line_item1.vendor_adjustments_total_excluding_tax).to eq(-26 - 13.0 / 2)
      end
    end

    context 'when there are only promotions that run by store' do  
      let(:promotions_run_by_vendor) { [] }
      let(:promotions_run_by_store) { [line_item_promotion_by_store_27, order_promotion_by_store_14] }
  
      it 'return 0$ adjustment since no promotions that run by vendor' do
        expect(line_item1.vendor_adjustments_total_excluding_tax).to eq 0
      end
    end

    context 'when there are no promotions' do  
      let(:promotions_run_by_vendor) { [] }
      let(:promotions_run_by_store) { [] }

      it 'return 0' do
        expect(line_item1.vendor_adjustments_total_excluding_tax).to eq 0
      end
    end
  end

  describe '#required_payway_payout?' do
    context 'when there are required_active_payout_profiles in product' do
      let(:payout_product) { build(:payway_payout_profile, active: true, verified_at: DateTime.current) }
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

  describe '#latest_private_metadata' do
    let(:line_item) { create(:line_item, price: 100) }

    before do
      # Mock the financial calculation methods to have predictable values
      allow(line_item).to receive(:subtotal).and_return(100.0)
      allow(line_item).to receive(:commission_rate).and_return(10.0)
      allow(line_item).to receive(:commission_amount).and_return(10.0)
      allow(line_item).to receive(:vendor_pre_tax_amount).and_return(90.0)
      allow(line_item).to receive(:pre_commission_amount).and_return(80.0)
      allow(line_item).to receive(:vendor_tax_total).and_return(5.0)
      allow(line_item).to receive(:vendor_adjustments_total_excluding_tax).and_return(-10.0)
    end

    context 'when line item has no existing private metadata' do
      before do
        allow(line_item).to receive(:private_metadata).and_return(nil)
      end

      it 'returns hash with only financial data' do
        result = line_item.latest_private_metadata

        expect(result).to eq({
          subtotal: 100.0,
          commission_rate: 10.0,
          commission_amount: 10.0,
          vendor_pre_tax_amount: 90.0,
          pre_commission_amount: 80.0,
          vendor_tax_total: 5.0,
          vendor_adjustments_total_excluding_tax: -10.0
        })
      end
    end

    context 'when line item has existing private metadata' do
      let(:existing_metadata) do
        {
          custom_field: 'custom_value',
          another_field: 123,
          subtotal: 50.0  # This should be overwritten
        }
      end

      before do
        allow(line_item).to receive(:private_metadata).and_return(existing_metadata)
      end

      it 'preserves existing metadata and updates financial fields' do
        result = line_item.latest_private_metadata

        expect(result).to eq({
          custom_field: 'custom_value',
          another_field: 123,
          subtotal: 100.0,  # Updated financial value
          commission_rate: 10.0,
          commission_amount: 10.0,
          vendor_pre_tax_amount: 90.0,
          pre_commission_amount: 80.0,
          vendor_tax_total: 5.0,
          vendor_adjustments_total_excluding_tax: -10.0
        })
      end

      it 'does not modify the original private_metadata' do
        original_metadata = line_item.private_metadata.dup
        line_item.latest_private_metadata

        expect(line_item.private_metadata).to eq(original_metadata)
      end
    end

    context 'when line item has empty private metadata hash' do
      before do
        allow(line_item).to receive(:private_metadata).and_return({})
      end

      it 'returns hash with only financial data' do
        result = line_item.latest_private_metadata

        expect(result).to eq({
          subtotal: 100.0,
          commission_rate: 10.0,
          commission_amount: 10.0,
          vendor_pre_tax_amount: 90.0,
          pre_commission_amount: 80.0,
          vendor_tax_total: 5.0,
          vendor_adjustments_total_excluding_tax: -10.0
        })
      end
    end
  end

  describe '#update_total_metadata' do
    let(:line_item) { create(:line_item, price: 100) }
    let(:expected_metadata) do
      {
        subtotal: 100.0,
        commission_rate: 5.0,
        commission_amount: 5.0,
        vendor_pre_tax_amount: 95.0,
        pre_commission_amount: 90.0,
        vendor_tax_total: 2.0,
        vendor_adjustments_total_excluding_tax: -5.0
      }
    end

    before do
      allow(line_item).to receive(:latest_private_metadata).and_return(expected_metadata)
    end

    it 'updates the private_metadata column with latest metadata' do
      expect(line_item).to receive(:update_column).with(:private_metadata, expected_metadata)
      
      line_item.update_total_metadata
    end

    it 'calls latest_private_metadata to get updated metadata' do
      expect(line_item).to receive(:latest_private_metadata).and_return(expected_metadata)
      allow(line_item).to receive(:update_column)
      
      line_item.update_total_metadata
    end
  end
end
