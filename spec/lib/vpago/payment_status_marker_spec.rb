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
        expect(subject).to receive(:save_payout_payments!).and_call_original

        subject.send(:transition_to_paid!)
      end
    end
  end

  describe '#transition_to_paid' do
    subject { described_class.new(payment, { payouts: checker.build_payout_profile_payments }) }

    it 'call transition_to_paid!' do  
      expect(subject).to receive(:complete_payment!).and_call_original
      expect(subject).to receive(:complete_order!).and_call_original
      expect(subject).to receive(:save_payout_payments!).and_call_original

      subject.send(:transition_to_paid!)

      payment.reload

      expect(payment.completed?).to be true
      expect(payment.order.completed?).to be true
      expect(payment.payout_profile_payments.size).to eq 2
    end
  end
  
  describe '#save_payout_payments!' do
    context 'when payouts present?' do
      subject { described_class.new(payment, { payouts: checker.build_payout_profile_payments }) }

      it 'save payout payments that pass to them' do
        result = subject.send(:save_payout_payments!)

        expect(result.size).to eq 2
        expect(result[0].persisted?).to be true
        expect(result[1].persisted?).to be true
    
        expect(result[0].payout_profile.bank_account_number).to eq '070486124'
        expect(result[1].payout_profile.bank_account_number).to eq '111111111'
    
        expect(result[0].amount).to eq 25
        expect(result[1].amount).to eq 30
      end
    end

    context 'when payouts not present?' do
      subject { described_class.new(payment) }

      it 'does nothing' do
        result = subject.send(:save_payout_payments!)

        expect(result).to be nil
      end
    end
  end
end