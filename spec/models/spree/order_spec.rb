require 'spec_helper'

RSpec.describe Spree::Order, type: :model do
  let(:gateway) { create(:payway_gateway, auto_capture: true) }
  let(:payment_source) { create(:payway_payment_source, payment_method: gateway) }

  let(:order) { create(:completed_order_with_totals) }

  let!(:payment) { 
    create(:payway_payment, payment_method: gateway, source: payment_source, order: order, amount: order.total, state: 'completed') 
  }

  context 'state machine' do
    context 'before transition cart -> any' do
      describe 'callback: ensure_valid_vendor_payment_methods' do
        let(:vendor1) { create(:vendor) }
        let(:vendor2) { create(:vendor) }
    
        let!(:vendor1_line_item1) { create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor1)) }
        let!(:vendor1_line_item2) { create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor1)) }

        let!(:vendor2_line_item1) { create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor2)) }
        let!(:vendor2_line_item2) { create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor2)) }

        context 'when line items from same vendor' do
          it 'does not return any error' do
            payment_method1 = create(:payment_method, vendor: vendor1)
            order = create(:order, state: :cart, line_items: [vendor1_line_item1, vendor1_line_item2])

            expect(order.line_items_from_same_vendor?).to be true
            expect(order.next).to be true
            expect(order.state).to eq 'address'
          end
        end

        context 'when line items from different vendor & each line item has no payment_methods' do
          it 'does not return any error' do
            order = create(:order, state: :cart, line_items: [vendor1_line_item1, vendor2_line_item1])

            expect(order.line_items_from_same_vendor?).to be false
            expect(order.vendor_payment_methods.size).to eq 0
            expect(order.next).to be true
            expect(order.state).to eq 'address'
          end
        end

        context 'when line items from different vendor & some line items has their own payment_methods' do
          it 'return error & keep order.state the same' do
            payment_method1 = create(:payment_method, vendor: vendor1)
            order = create(:order, state: :cart, line_items: [vendor1_line_item1, vendor2_line_item2])
  
            expect(order.line_items_from_same_vendor?).to be false
            expect(order.vendor_payment_methods.size).to eq 1

            expect(order.next).to be false
            expect(order.state).to eq 'cart'
            expect(order.errors.messages).to include(line_items: include('some_payment_methods_cant_be_used_across_vendors'))
          end
        end
      end
    end
  end

  context '#cancel' do
    it 'marks the payway to void' do
      allow_any_instance_of(Spree::Shipment).to receive(:refresh_rates).and_return(true)

      order.cancel
      order.reload

      expect(order.payments.first).to be_void
    end
  end

  describe '#line_items_from_same_vendor?' do
    let(:vendor1) { create(:vendor) }
    let(:vendor2) { create(:vendor) }
    let(:order) { create(:order) }

    it 'return true when line item from same vendor' do
      line_item1 = create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor1))
      line_item2 = create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor1))
      order.reload

      expect(order.line_items.size).to eq 2
      expect(order.line_items_from_same_vendor?).to be true
    end

    it 'return false when line item from different vendor' do
      line_item1 = create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor1))
      line_item2 = create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor2))
      order.reload

      expect(order.line_items.size).to eq 2
      expect(order.line_items_from_same_vendor?).to be false
    end
  end

  describe '#available_payment_methods' do
    let(:vendor1) { create(:vendor) }
    let(:vendor2) { create(:vendor) }

    let(:order) { create(:order) }

    let!(:line_item1) { create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor1)) }
    let!(:line_item2) { create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor2)) }

    context 'when have vendor payment methods in line items' do
      let!(:payment_method0) { create(:payment_method) }
      let!(:payment_method1) { create(:payment_method, vendor: vendor1) }
      let!(:payment_method2) { create(:payment_method, vendor: vendor2) }

      it 'return all payment methods associated with line items vendor' do
        expect(order.available_payment_methods.size).to eq 2
        expect(order.available_payment_methods.pluck(:id)).to eq [payment_method1.id, payment_method2.id]
      end

      it 'return does not return any store payment methods (has no associated vendor)' do
        expect(order.available_payment_methods.pluck(:id)).not_to include(payment_method0.id)
      end
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

  describe '#available_vendor_payment_methods' do
    let(:vendor1) { create(:vendor) }
    let(:vendor2) { create(:vendor) }
    let(:order) { create(:order) }

    before do
      create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor1))
      create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor2))
    end

    context 'when user is a ticket seller' do
      before do
        allow(order).to receive(:ticket_seller_user?).and_return(true)
      end

      it 'returns all vendor payment methods' do
        payment_method1 = create(:payment_method, vendor: vendor1)
        payment_method2 = create(:payment_method, vendor: vendor2, type: 'Spree::PaymentMethod::Check')

        order.stub(:vendor_payment_methods) { [payment_method1, payment_method2] }
        
        expect(order.available_vendor_payment_methods).to match_array([payment_method1, payment_method2])
      end
    end

    context 'when user is not a ticket seller' do
      before do
        allow(order).to receive(:ticket_seller_user?).and_return(false)
      end

      it 'returns vendor payment methods excluding the ones of type Check' do
        payment_method1 = create(:payment_method, vendor: vendor1)
        payment_method2 = create(:payment_method, vendor: vendor2)
        payment_method_check = create(:payment_method, vendor: vendor1, type: 'Spree::PaymentMethod::Check')

        order.stub(:vendor_payment_methods) { [payment_method1, payment_method2, payment_method_check] }

        expect(order.available_vendor_payment_methods).to match_array([payment_method1, payment_method2])
        expect(order.available_vendor_payment_methods).not_to include(payment_method_check)
      end
    end
  end
end
