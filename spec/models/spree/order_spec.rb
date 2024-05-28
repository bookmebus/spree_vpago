require 'spec_helper'

RSpec.describe Spree::Order, type: :model do
  let(:gateway) { create(:payway_gateway, auto_capture: true) }
  let(:payment_source) { create(:payway_payment_source, payment_method: gateway) }

  let(:order) { create(:completed_order_with_totals) }

  let!(:payment) { 
    create(:payway_payment, payment_method: gateway, source: payment_source, order: order, amount: order.total, state: 'completed') 
  }

  context '#cancel' do
    it 'marks the payway to void' do
      allow_any_instance_of(Spree::Shipment).to receive(:refresh_rates).and_return(true)

      order.cancel
      order.reload

      expect(order.payments.first).to be_void
    end
  end

  describe '#allowed_payout?' do
    let(:order) { build(:order) }

    context 'when adjustment_total > 0' do
      it 'returns false' do
        order.adjustment_total = 1
        expect(order.allowed_payout?).to be false
      end
    end
  
    context 'when included_tax_total > 0' do
      it 'returns false' do
        order.included_tax_total = 1
        expect(order.allowed_payout?).to be false
      end
    end
  
    context 'when additional_tax_total > 0' do
      it 'returns false' do
        order.additional_tax_total = 1
        expect(order.allowed_payout?).to be false
      end
    end
  
    context 'when promo_total > 0' do
      it 'returns false' do
        order.promo_total = 1
        expect(order.allowed_payout?).to be false
      end
    end
  
    context 'when all totals are 0' do
      it 'returns true' do
        order.adjustment_total = 0
        order.included_tax_total = 0
        order.additional_tax_total = 0
        order.promo_total = 0

        expect(order.allowed_payout?).to be true
      end
    end
  end

  describe '#required_payway_payout?' do
    context 'when allowed_payout is false' do
      before do
        order.promo_total = 1
        expect(order.allowed_payout?).to be false
      end

      it 'return false' do
        expect(order.required_payway_payout?).to be false
      end
    end

    context 'when allowed_payout is true' do
      let(:line_item_a) { create(:line_item) }
      let(:line_item_b) { create(:line_item) }
      let(:order) { create(:order, line_items: [line_item_a, line_item_b])}

      before do
        order.adjustment_total = 0
        order.included_tax_total = 0
        order.additional_tax_total = 0
        order.promo_total = 0

        expect(order.allowed_payout?).to be true
      end

      it 'return true when any of line item is required payway payout' do
        allow(line_item_a).to receive(:required_payway_payout?).and_return(true)
        allow(line_item_b).to receive(:required_payway_payout?).and_return(false)
  
        expect(order.required_payway_payout?).to be true
      end
    end
  end

  describe "#available_payment_methods" do
    let(:payment_method1) { create(:payway_v2_gateway) }
    let(:payment_method2) { create(:acleda_payment_method) }

    let(:order) { create(:order) }

    context "when required_payway_payout is true" do
      before do
        allow(order).to receive(:required_payway_payout?).and_return(true)
        allow(order).to receive(:collect_payment_methods).with(nil).and_return([payment_method1, payment_method2])
      end

      it "returns payment methods of type payway_v2" do
        expect(payment_method1.type_payway_v2?).to be true
        expect(order.available_payment_methods).to eq([payment_method1])
      end
    end

    context "when required_payway_payout is false" do
      before do
        allow(order).to receive(:required_payway_payout?).and_return(false)
        allow(order).to receive(:collect_payment_methods).with(nil).and_return([payment_method1, payment_method2])
      end
      
      it "returns all payment methods" do
        expect(order.available_payment_methods).to eq([payment_method1, payment_method2])
      end
    end
  end
end
