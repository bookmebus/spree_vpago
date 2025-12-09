require 'spec_helper'

RSpec.describe Vpago::PaymentCapturerJob, type: :job do
  let(:order) { create(:order_with_line_items, state: :payment) }
  let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order) }

  it 'is enqueued on the payment_processing queue' do
    expect {
      described_class.perform_later(payment.id)
    }.to have_enqueued_job(described_class)
      .with(payment.id)
      .on_queue('payment_processing')
  end

  describe '#perform' do
    context 'when capture action is available' do
      before do
        allow(payment).to receive(:actions).and_return(['capture'])
        allow(Spree::Payment).to receive(:find).with(payment.id).and_return(payment)
      end

      it 'calls capture! on the payment' do
        expect(payment).to receive(:capture!)
        described_class.new.perform(payment.id)
      end
    end

    context 'when capture action is not available' do
      before do
        allow(payment).to receive(:actions).and_return([])
        allow(Spree::Payment).to receive(:find).with(payment.id).and_return(payment)
      end

      it 'does not call capture!' do
        expect(payment).not_to receive(:capture!)
        described_class.new.perform(payment.id)
      end
    end
  end
end
