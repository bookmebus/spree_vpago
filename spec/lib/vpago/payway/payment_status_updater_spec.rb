require 'spec_helper'

RSpec.describe Vpago::Payway::PaymentStatusUpdater, type: :model do
  let(:gateway) { create(:payway_gateway, auto_capture: true) }
  let(:payment_source) { create(:payway_payment_source, payment_method: gateway) }

  let(:order) { OrderWalkthrough.up_to( :payment) }
  let(:payment) { create(:payway_payment, payment_method: gateway, source: payment_source, order: order) }

  let(:status_updater) {
    payment.process!
    Vpago::Payway::PaymentStatusUpdater.new(payment)
  }

  describe 'success?' do
    it 'return true if payment_status source is success' do
      allow(status_updater.payment.source).to receive(:payment_status).and_return "success"
      expect(status_updater.success?).to eq true
    end

    it 'return false f payment_status source is failed' do
      allow(status_updater.payment.source).to receive(:payment_status).and_return "failed"
      expect(status_updater.success?).to eq false
    end
  end

  describe '#error_message' do
    it 'return nil f payment_status source is success' do
      allow(status_updater.payment.source).to receive(:payment_status).and_return "success"
      expect(status_updater.error_message).to eq nil
    end
    
    it 'return payment_status if payment source has error' do
      allow(status_updater.payment.source).to receive(:payment_status).and_return "failed"
      allow(status_updater.payment.source).to receive(:payment_description).and_return "invalid transaction id"
      expect(status_updater.error_message).to eq "invalid transaction id"
    end

  end

  describe '#update_payment_source' do
    context 'payway_trans_status success' do
      it "update payment source payment_status to success" do
        payway_tran = double(:payway_trans_status, :success? => true )
        allow(status_updater).to receive(:check_payway_status).and_return(payway_tran)
        
        # load data
        status_updater.send(:prepare_and_load_payway_status)

        status_updater.send(:update_payment_source)
        payment_source.reload

        expect(payment_source.payment_status).to eq 'success'
      end
    end

    context 'payway_trans_status# failed' do
      it "update payment source status to failed and save error_message" do
        payway_tran = double(:payway_trans_status, :success? => false, error_message: 'Transaction is not found' )
        allow(status_updater).to receive(:check_payway_status).and_return(payway_tran)

        # load data
        status_updater.send(:prepare_and_load_payway_status)

        status_updater.send(:update_payment_source)
        payment_source.reload

        expect(payment_source.payment_status).to eq 'failed'
        expect(payment_source.payment_description).to eq payway_tran.error_message
      end
    end
  end

  describe '#complete_payment!' do
    it 'marks payment state to completed' do
      status_updater.send(:complete_payment!)
      payment.reload

      expect(payment.state).to eq 'completed'
    end
  end
  describe '#complete_order!' do
    it 'updates order state to be complete' do

      status_updater.send(:complete_order!)
      order.reload

      expect(order.state).to eq 'complete'
      expect(order.completed_at).not_to be_nil
    end
  end

  describe '#transition_to_paid!' do
    it 'mark payment and order state to be complete' do
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
      payway_tran = double(:payway_trans_status, :success? => false, error_message: 'Transaction is not found' )
      allow(status_updater).to receive(:check_payway_status).and_return(payway_tran)

      # load data
      status_updater.send(:prepare_and_load_payway_status)

      status_updater.send(:transition_to_failed!)
      payment.reload
      order.reload

      expect(payment.state).to eq 'failed'
      expect(order.state).to eq 'payment'
    end
  end

end
