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

  context 'when payment is pending' do
    before do
      # Stub `pending?` to return true so `capture!` is called
      allow_any_instance_of(Spree::Payment).to receive(:pending?).and_return(true)
      expect(payment.state).to eq 'checkout'
    end
  
    it 'calls capture! on the payment if it is pending' do
      expect_any_instance_of(Spree::Payment).to receive(:capture!).and_call_original
      described_class.new.perform(payment.id)
  
      expect(payment.reload.state).to eq 'completed'
    end    
  end

  context 'when payment is not pending' do
    before do
      allow_any_instance_of(Spree::Payment).to receive(:pending?).and_return(false)
      expect(payment.state).to eq 'checkout'
    end

    it 'does not call capture!' do
      expect_any_instance_of(Spree::Payment).not_to receive(:capture!)
      described_class.new.perform(payment.id)

      expect(payment.reload.state).to eq 'checkout'
    end
  end
end
