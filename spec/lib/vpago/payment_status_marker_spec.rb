require 'spec_helper'

RSpec.describe Vpago::PaymentStatusMarker do
  let!(:default_payout_profile) { create(:payway_payout_profile, active: true, bank_account_number: '333', default: true, verified_at: DateTime.current)}

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
        expect(subject).to receive(:transition_to_failed!).and_call_original

        subject.send(:update_payment_and_order)
      end
    end
  end

  describe '#transition_to_paid' do
    subject { described_class.new(payment) }

    it 'call transition_to_paid!' do  
      expect(subject).to receive(:complete_payment!).and_call_original
      expect(subject).to receive(:complete_order!).and_call_original
      expect(subject).to receive(:confirm_payouts!).and_call_original

      subject.send(:transition_to_paid!)

      payment.reload

      expect(payment.completed?).to be true
      expect(payment.order.completed?).to be true
    end
  end

  describe '#confirm_payouts!' do
    # payouts are auto created when payment created, we have to delete them to manually create for test.
    before { Spree::Payout.destroy_all }

    context 'when payout is confirmed' do
      let!(:payout1) { create(:payout, payment: payment, amount: 25.0, state: :created) }
      let!(:payout2) { create(:payout, payment: payment, amount: 30.0, state: :created) }

      subject { described_class.new(payment, { payout_total: 25.0 + 30.0 }) }

      it 'save update payment.payouts state to confirm' do
        subject.send(:confirm_payouts!)

        expect(payout1.reload.state).to eq('confirmed')
        expect(payout2.reload.state).to eq('confirmed')
      end
    end

    context 'when payout is not confirmed' do
      subject { described_class.new(payment, { payout_total: 0 }) }

      let!(:payout1) { create(:payout, payment: payment, amount: 25.0, state: :created) }
      let!(:payout2) { create(:payout, payment: payment, amount: 30.0, state: :created) }

      it 'does nothing' do
        subject.send(:confirm_payouts!)

        expect(payout1.reload.state).to eq 'created'
        expect(payout2.reload.state).to eq 'created'
      end
    end
  end
end