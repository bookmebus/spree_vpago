require 'spec_helper'

RSpec.describe Vpago::PaymentStatusMarker do
  let(:payment_method) { create(:payway_v2_gateway) }
  let(:payment) { create(:payway_payment, state: :processing, payment_method: payment_method) }

  let(:checker) { Vpago::PaywayV2::TransactionStatus.new(payment) }

  before do
    allow(checker).to receive(:check_transaction_url).and_return('https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/check-transaction')
    VCR.use_cassette('payway_v2_check_transaction_status_0') { checker.call }
  end

  describe '#call' do
    subject { described_class.new(payment, { status: true }) }

    it 'update source, payment & order' do
      expect(subject).to receive(:update_payment_source).and_call_original
      expect(subject).to receive(:update_payment_and_order).and_call_original

      subject.call
    end
  end

  describe '#update_payment_and_order' do
    context 'when status true' do
      subject { described_class.new(payment, { status: true }) }

      it 'call transition_to_paid!' do  
        expect(subject).to receive(:transition_to_paid!).and_call_original

        subject.send(:update_payment_and_order)
      end
    end

    context 'when status false' do
      subject { described_class.new(payment, { status: false }) }

      it 'call transition_to_failed!' do  
        expect(subject).to receive(:complete_payment!).and_call_original
        expect(subject).to receive(:complete_order!).and_call_original

        subject.send(:transition_to_paid!)
      end
    end
  end

  describe '#transition_to_paid' do
    subject { described_class.new(payment) }

    it 'call transition_to_paid!' do  
      expect(subject).to receive(:complete_payment!).and_call_original
      expect(subject).to receive(:complete_order!).and_call_original

      subject.send(:transition_to_paid!)

      payment.reload

      expect(payment.completed?).to be true
      expect(payment.order.completed?).to be true
    end
  end
end