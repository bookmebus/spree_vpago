require 'spec_helper'

RSpec.describe Vpago::PaywayV2::PaymentRequestUpdater, type: :model do
  let(:gateway) { create(:payway_v2_gateway, auto_capture: true) }
  let(:payment_source) { create(:payway_payment_source, payment_method: gateway) }
  let(:user) { create(:user) }
  let(:order) { OrderWalkthrough.up_to(:payment) }
  let(:payment) { create(:payway_payment, payment_method: gateway, source: payment_source, order: order , state: 'processing') }

  describe 'ineligible items' do
    it 'marks the payment as failed due to insufficient stock' do
      allow(order.line_items).to receive(:all?).and_return(false)
      options = { updated_by_user_id: user.id }
      updater = Vpago::PaywayV2::PaymentRequestUpdater.new(payment, options)
      updater.call
      
      expect(payment.state).to eq('failed')
      expect(payment.source.payment_description).to eq('Items are not eligible due to insufficient stock')
    end
  end

  describe 'gateway timeout' do
    it 'leaves the payment untouched instead of marking it failed' do
      allow_any_instance_of(gateway.class).to receive(:check_transaction).and_raise(Faraday::TimeoutError)
      options = { updated_by_user_id: user.id }
      updater = Vpago::PaywayV2::PaymentRequestUpdater.new(payment, options)

      expect { updater.call }.not_to raise_error
      expect(payment.reload.state).to eq('processing')
    end
  end
end
