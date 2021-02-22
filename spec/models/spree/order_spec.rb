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

end
