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

  describe '#generate_line_items_total_metadata' do
    let(:vendor_a) { create(:vendor, commission_rate: 10) }
    let(:vendor_b) { create(:vendor, commission_rate: 15) }

    let(:product_a) { create(:product_in_stock, vendor: vendor_a) }
    let(:product_b) { create(:product_in_stock, vendor: vendor_b) }

    let(:line_item_a) { create(:line_item, product: product_a) }
    let(:line_item_b) { create(:line_item, product: product_b) }

    let(:order) { create(:order, line_items: [line_item_a, line_item_b])}

    it 'save commission_rate, commission_amount, pre_commission_amount, subtotal_with_vendor_adjustment_total, vendor_adjustment_total to private_metadata' do
      expect(line_item_a.private_metadata).to eq({})
      expect(line_item_b.private_metadata).to eq({})

      order.generate_line_items_total_metadata

      expect(line_item_a.private_metadata).to eq({"commission_amount"=>1.0, "commission_rate"=>10.0, "pre_commission_amount"=>9.0, "subtotal"=>10.0, "vendor_adjustments_total_excluding_tax"=>0.0, "vendor_pre_tax_amount"=>10.0, "vendor_tax_total"=>0.0})
      expect(line_item_b.private_metadata).to eq({"commission_amount"=>1.5, "commission_rate"=>15.0, "pre_commission_amount"=>8.5, "subtotal"=>10.0, "vendor_adjustments_total_excluding_tax"=>0.0, "vendor_pre_tax_amount"=>10.0, "vendor_tax_total"=>0.0})
    end
  end

  describe '#required_payway_payout?' do
    let(:order) { create(:order_ready_to_ship, line_items_count: 2) }

    before do
      order.adjustment_total = 0
      order.included_tax_total = 0
      order.additional_tax_total = 0
      order.promo_total = 0
    end

    context 'when some line items are required payway payout' do
      it 'return true' do
        allow(order.line_items[0]).to receive(:required_payway_payout?).and_return(true)
        allow(order.line_items[1]).to receive(:required_payway_payout?).and_return(false)
        
        # true even shipment does not required
        allow(order.shipments[0]).to receive(:required_payway_payout?).and_return(false)

        expect(order.required_payway_payout?).to be true
      end
    end

    context 'when some shipments are required payway payout' do
      it 'return true' do
        allow(order.shipments[0]).to receive(:required_payway_payout?).and_return(true)
  
        # true even line items does not required
        allow(order.line_items[0]).to receive(:required_payway_payout?).and_return(false)
        allow(order.line_items[1]).to receive(:required_payway_payout?).and_return(false)

        expect(order.required_payway_payout?).to be true
      end
    end

    context 'when no shipment or line item are required payway payout' do
      it 'return true' do
        allow(order.shipments[0]).to receive(:required_payway_payout?).and_return(false)
  
        allow(order.line_items[0]).to receive(:required_payway_payout?).and_return(false)
        allow(order.line_items[1]).to receive(:required_payway_payout?).and_return(false)

        expect(order.required_payway_payout?).to be false
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
