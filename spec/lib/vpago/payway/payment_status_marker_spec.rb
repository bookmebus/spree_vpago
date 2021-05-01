require 'spec_helper'

RSpec.describe Vpago::Payway::PaymentStatusMarker, type: :model do
  let(:gateway) { create(:payway_gateway, auto_capture: true) }
  let(:payment_source) { create(:payway_payment_source, payment_method: gateway) }

  let(:order) { OrderWalkthrough.up_to( :payment) }
  let(:payment) { create(:payway_payment, payment_method: gateway, source: payment_source, order: order) }
  let(:user) { create(:user)}

  before(:each) { payment.process! }

  describe '#update_payment_source' do
    context 'status true' do
      it "update payment source payment_status to success" do
        options = {
          status: true,
          updated_by_user_id: user.id,
          updated_reason: 'manually-updated'
        }

        updated_by_user_at = Time.zone.now
        allow(Time.zone).to receive(:now).and_return(updated_by_user_at)

        status_updater = Vpago::Payway::PaymentStatusMarker.new(payment, options)

        status_updater.send(:update_payment_source)
        payment_source.reload

        expect(payment_source.payment_status).to eq 'success'
        expect(payment_source.updated_by_user_id).to eq user.id
        expect(payment_source.updated_reason).to eq 'manually-updated'
        expect(payment_source.updated_by_user_at).to eq updated_by_user_at
      end
    end

    context 'status false' do
      it "update payment source status to failed and save error_message" do
        description = 'error-message'

        options = {
          status: false,
          description: description,
          updated_by_user_id: user.id,
          updated_reason: 'manually-updated'
        }

        status_updater = Vpago::Payway::PaymentStatusMarker.new(payment, options)

        status_updater.send(:update_payment_source)
        payment_source.reload

        expect(payment_source.payment_status).to eq 'failed'
        expect(payment_source.payment_description).to eq description
        expect(payment_source.updated_by_user_id).to eq nil
        expect(payment_source.updated_by_user_at).to eq nil
        expect(payment_source.updated_reason).to eq nil
      end
    end
  end

  describe '#complete_payment!' do
    it 'marks payment state to completed' do
      status_updater = Vpago::Payway::PaymentStatusMarker.new(payment, status: true)
      status_updater.send(:complete_payment!)
      payment.reload

      expect(payment.state).to eq 'completed'
    end
  end
  describe '#complete_order!' do
    it 'updates order state to be complete' do

      status_updater = Vpago::Payway::PaymentStatusMarker.new(payment, status: true)
      status_updater.send(:complete_order!)
      order.reload

      expect(order.state).to eq 'complete'
      expect(order.completed_at).not_to be_nil
    end
  end

  describe '#transition_to_paid!' do
    it 'mark payment and order state to be complete' do
      status_updater = Vpago::Payway::PaymentStatusMarker.new(payment, status: true)
      status_updater.send(:transition_to_paid!)
      payment.reload
      order.reload

      expect(payment.state).to eq 'completed'

      expect(order.payment_state).to eq 'paid'
      expect(order.state).to eq 'complete'
      expect(order.completed_at).not_to be_nil
    end
  end

  describe '#transition_to_failed!' do
    it 'mark payment and order state to be complete' do
      status_updater = Vpago::Payway::PaymentStatusMarker.new(payment, status: false)

      status_updater.send(:transition_to_failed!)
      payment.reload
      order.reload

      expect(payment.state).to eq 'failed'
      expect(order.state).to eq 'payment'
    end
  end

end
