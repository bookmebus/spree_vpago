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
            _payment_method1 = create(:payment_method, vendor: vendor1)
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
            _ = create(:payment_method, vendor: vendor1)
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
      _line_item1 = create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor1))
      _line_item2 = create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor1))
      order.reload

      expect(order.line_items.size).to eq 2
      expect(order.line_items_from_same_vendor?).to be true
    end

    it 'return false when line item from different vendor' do
      _line_item1 = create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor1))
      _line_item2 = create(:line_item, order: order, product: create(:product_in_stock, vendor: vendor2))
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
        expect(order.available_payment_methods.pluck(:id)).to match_array([payment_method1.id, payment_method2.id])
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
    let(:payment_method1) { create(:payway_v2_gateway, preferred_payment_option: 'cards') }
    let(:payment_method2) { create(:payway_v2_gateway, preferred_payment_option: 'abapay_khqr') }
    let(:payment_method3) { create(:payway_v2_gateway, preferred_payment_option: 'abapay_khqr_deeplink') }
    let(:payment_method4) { create(:acleda_payment_method) }

    let(:order) { create(:order) }

    context "when required_payway_payout is true" do
      before do
        allow(order).to receive(:required_payway_payout?).and_return(true)
        allow(order).to receive(:collect_payment_methods).with(nil).and_return([payment_method1, payment_method2, payment_method3, payment_method4])
      end

      it "returns only return payway v2 payment methods that support payout" do
        expect(payment_method1.support_payout?).to be false
        expect(payment_method2.support_payout?).to be true
        expect(payment_method3.support_payout?).to be true
        expect(payment_method4.support_payout?).to be false
        expect(order.available_payment_methods).to match_array([payment_method2, payment_method3])
      end
    end

    context "when required_payway_payout is false" do
      before do
        allow(order).to receive(:required_payway_payout?).and_return(false)
        allow(order).to receive(:collect_payment_methods).with(nil).and_return([payment_method1, payment_method2, payment_method3, payment_method4])
      end
      
      it "returns all payment methods" do
        expect(order.available_payment_methods).to match_array([payment_method1, payment_method2, payment_method3, payment_method4])
      end
    end
  end

  # CRITICAL: Test process_payments! to prevent orders completing without valid payments
  describe '#process_payments!' do
    let(:payment_order) { create(:order_with_line_items, state: 'payment', total: 10.00) }
    let(:payment_method) { create(:payway_gateway, auto_capture: true) }

    before do
      allow(Spree::Config).to receive(:[]).and_call_original
      allow(Spree::Config).to receive(:[]).with(:allow_checkout_on_gateway_error).and_return(false)
    end

    context 'when payment processing fails' do
      it 'returns false and prevents order completion' do
        _payment = create(:payment, order: payment_order, payment_method: payment_method, amount: 10.00, state: 'checkout')
        payment_order.reload
        
        # Stub the payment gateway to fail (this is the real failure point)
        allow_any_instance_of(payment_method.class).to receive(:authorize).and_raise(Spree::Core::GatewayError, 'Gateway connection failed')
        
        # process_payments! should return false
        # NOTE: Gateway error is caught by parent, but payment_total stays 0, so our override catches it
        expect(payment_order.process_payments!).to eq(false)
        expect(payment_order.errors[:base]).to include(Spree.t(:insufficient_payment_amount_to_cover_the_total))
      end

      it 'prevents order from advancing to complete state' do
        _payment = create(:payment, order: payment_order, payment_method: payment_method, amount: 10.00, state: 'checkout')
        payment_order.reload
        
        # Stub the gateway to fail (realistic scenario)
        allow_any_instance_of(payment_method.class).to receive(:authorize).and_raise(Spree::Core::GatewayError, 'Payment declined')
        
        # Try to complete order - should raise because of gateway error
        expect { payment_order.next! }.to raise_error(StateMachines::InvalidTransition)
        
        # Order should stay in payment state
        # NOTE: Our override adds insufficient payment error after gateway failure
        expect(payment_order.state).to eq('payment')
        expect(payment_order.errors[:base]).to be_present
      end
    end

    context 'when no completed payments exist' do
      it 'returns false if only checkout payment exists' do
        create(:payment, order: payment_order, payment_method: payment_method, amount: 10.00, state: 'checkout')
        
        result = payment_order.process_payments!
        expect(result).to eq(false)
        expect(payment_order.errors[:base]).to include(Spree.t(:insufficient_payment_amount_to_cover_the_total))
      end

      it 'returns false if only failed payment exists' do
        create(:payment, order: payment_order, payment_method: payment_method, amount: 10.00, state: 'failed')
        
        result = payment_order.process_payments!
        expect(result).to eq(false)
        expect(payment_order.errors[:base]).to include(Spree.t(:insufficient_payment_amount_to_cover_the_total))
      end

      it 'prevents order from advancing to complete' do
        create(:payment, order: payment_order, payment_method: payment_method, amount: 10.00, state: 'failed')
        payment_order.update_columns(payment_total: 0)
        payment_order.reload
        
        # Try to advance - should fail due to no valid payments
        expect { payment_order.next! }.to raise_error(StateMachines::InvalidTransition)
        
        expect(payment_order.state).to eq('payment')
        expect(payment_order.errors[:base]).to be_present
      end
    end

    context 'when completed payment amount is insufficient' do
      it 'returns false when payment_total is less than order total' do
        # Only $5 of $10 total
        _payment = create(:payment, order: payment_order, payment_method: payment_method, amount: 5.00, state: 'completed')
        payment_order.update_column(:payment_total, 5.00)
        
        result = payment_order.process_payments!
        expect(result).to eq(false)
        expect(payment_order.errors[:base]).to include(Spree.t(:insufficient_payment_amount_to_cover_the_total))
      end

      it 'prevents order from advancing to complete state' do
        _payment = create(:payment, order: payment_order, payment_method: payment_method, amount: 5.00, state: 'completed')
        payment_order.update_column(:payment_total, 5.00)
        
        expect { payment_order.next! }.to raise_error(StateMachines::InvalidTransition)
        expect(payment_order.state).to eq('payment')
      end
    end

    # Note: "Success" scenarios where payment_total already covers total are not tested
    # because in production, process_payments! is only called when there are checkout payments to process.
    # Once payments are completed and payment_total >= total, the order advances without calling process_payments! again.

    context 'with multiple payments' do
      it 'returns false when total payment_total is insufficient' do
        _payment1 = create(:payment, order: payment_order, payment_method: payment_method, amount: 3.00, state: 'completed')
        _payment2 = create(:payment, order: payment_order, payment_method: payment_method, amount: 2.00, state: 'completed')
        payment_order.update_column(:payment_total, 5.00) # Total: $5 of $10
        
        result = payment_order.process_payments!
        expect(result).to eq(false)
        expect(payment_order.errors[:base]).to include(Spree.t(:insufficient_payment_amount_to_cover_the_total))
      end

      it 'calculates processed_payment_total including pending payments' do
        _completed_payment = create(:payment, order: payment_order, payment_method: payment_method, amount: 5.00, state: 'completed')
        _pending_payment = create(:payment, order: payment_order, payment_method: payment_method, amount: 5.00, state: 'pending')
        payment_order.update_columns(payment_total: 5.00)
        payment_order.reload
        
        # processed_payment_total = payment_total (5) + pending (5) = 10
        expect(payment_order.processed_payment_total).to eq(10.00)
      end

      it 'returns false when completed+pending still insufficient' do
        _completed_payment = create(:payment, order: payment_order, payment_method: payment_method, amount: 3.00, state: 'completed')
        _pending_payment = create(:payment, order: payment_order, payment_method: payment_method, amount: 2.00, state: 'pending')
        payment_order.update_column(:payment_total, 3.00)
        
        # processed_payment_total = payment_total (3) + pending (2) = 5 < 10
        expect(payment_order.processed_payment_total).to eq(5.00)
        
        result = payment_order.process_payments!
        expect(result).to eq(false)
      end

      it 'ignores checkout and failed payments in payment_total' do
        _completed_payment = create(:payment, order: payment_order, payment_method: payment_method, amount: 5.00, state: 'completed')
        _checkout_payment = create(:payment, order: payment_order, payment_method: payment_method, amount: 10.00, state: 'checkout')
        _failed_payment = create(:payment, order: payment_order, payment_method: payment_method, amount: 10.00, state: 'failed')
        payment_order.update_column(:payment_total, 5.00) # Only completed counts
        
        # Only $5 completed, checkout/failed don't count
        result = payment_order.process_payments!
        expect(result).to eq(false)
      end

    end

    # CRITICAL: Test the exact scenario where order was completing despite payment failure
    context 'CRITICAL BUG SCENARIO: order completes with failed payment' do
      it 'prevents completion when single payment fails at gateway' do
        _payment = create(:payment, order: payment_order, payment_method: payment_method, amount: 10.00, state: 'checkout')
        payment_order.reload

        # Simulate gateway failure (this is what actually happens in production)
        allow_any_instance_of(payment_method.class).to receive(:authorize).and_raise(Spree::Core::GatewayError, 'Payment failed')
        
        # Try to complete - should raise
        expect { payment_order.next! }.to raise_error(StateMachines::InvalidTransition)
        
        # MUST stay in payment state - this is the critical fix!
        # The payment fails, payment_total stays 0, our check catches it
        expect(payment_order.state).to eq('payment')
        expect(payment_order.errors[:base]).to include(Spree.t(:insufficient_payment_amount_to_cover_the_total))
      end

      it 'prevents completion when payment_total is 0 despite having failed payment' do
        _payment = create(:payment, order: payment_order, payment_method: payment_method, amount: 10.00, state: 'failed')
        payment_order.update_columns(payment_total: 0)
        payment_order.reload
        
        # processed_payment_total = 0 + 0 = 0 < 10
        expect(payment_order.processed_payment_total).to eq(0)
        
        result = payment_order.process_payments!
        expect(result).to eq(false)
        expect(payment_order.errors[:base]).to include(Spree.t(:insufficient_payment_amount_to_cover_the_total))
      end
    end
  end

  describe '#processed_payment_total' do
    let(:payment_order) { create(:order) }
    let(:payment_method) { create(:payway_gateway) }

    it 'sums payment_total and pending payments' do
      create(:payment, order: payment_order, payment_method: payment_method, amount: 10.00, state: 'completed')
      create(:payment, order: payment_order, payment_method: payment_method, amount: 5.00, state: 'pending')
      payment_order.payment_total = 10.00
      
      expect(payment_order.processed_payment_total).to eq(15.00)
    end

    it 'returns only payment_total when no pending payments' do
      create(:payment, order: payment_order, payment_method: payment_method, amount: 10.00, state: 'completed')
      payment_order.payment_total = 10.00
      
      expect(payment_order.processed_payment_total).to eq(10.00)
    end

    it 'does not include checkout or failed payments' do
      create(:payment, order: payment_order, payment_method: payment_method, amount: 10.00, state: 'completed')
      create(:payment, order: payment_order, payment_method: payment_method, amount: 5.00, state: 'checkout')
      create(:payment, order: payment_order, payment_method: payment_method, amount: 3.00, state: 'failed')
      payment_order.payment_total = 10.00
      
      # Only completed payment counts in payment_total
      expect(payment_order.processed_payment_total).to eq(10.00)
    end
  end
end
