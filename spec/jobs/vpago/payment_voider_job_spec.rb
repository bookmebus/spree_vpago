require 'spec_helper'

RSpec.describe Vpago::PaymentVoiderJob, type: :job do
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
    context 'when void action is available' do
      before do
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_void?).and_return(true)
      end

      it 'calls void_transaction! on the payment' do
        expect_any_instance_of(Spree::Payment).to receive(:void_transaction!)
        described_class.new.perform(payment.id)
      end
    end

    context 'when void action is not available' do
      before do
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_void?).and_return(false)
      end

      it 'does not call void_transaction!' do
        expect_any_instance_of(Spree::Payment).not_to receive(:void_transaction!)
        described_class.new.perform(payment.id)
      end
    end
  end
end
