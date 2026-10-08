require 'spec_helper'

RSpec.describe Vpago::PaymentProcessorJob, type: :job do
  let!(:payment) { create(:payway_v2_payment) }
  let!(:processor) { Vpago::PaymentProcessor.new(payment: payment) }

  it 'is enqueued on the payment_processing queue' do
    expect {
      described_class.perform_later(payment_number: payment.number)
    }.to have_enqueued_job(described_class)
      .with(payment_number: payment.number)
      .on_queue('payment_processing')
  end

  describe '#perform' do
    it 'find payment & call process payment' do
      expect(Spree::Payment).to receive(:find_by!).with({ number: payment.number }).and_return(payment)
      expect(Vpago::PaymentProcessor).to receive(:new).with(payment: payment).and_return(processor)
      expect(processor).to receive(:call)

      Vpago::PaymentProcessorJob.perform_now({ payment_number: payment.number })
    end
  end
end
