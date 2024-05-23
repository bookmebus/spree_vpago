require 'spec_helper'

RSpec.describe Vpago::PaywayV2::TransactionStatus do
  let(:payment_method) { create(:payway_v2_gateway) }
  let(:payment) { create(:payment, payment_method: payment_method) }

  subject { described_class.new(payment) }

  before do
    allow(subject).to receive(:check_transaction_url).and_return('https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/check-transaction')
  end

  describe '#call' do
    it 'call request to check_remote_status & save to response' do
      expect(subject).to receive(:check_remote_status).and_call_original

      VCR.use_cassette('payway_v2_check_transaction_status_0') do
        subject.call
      end

      expect(subject.json_response['payout'].to_json).to eq([
        { acc: "070486124", amt: "25.00", acc_name: "*********ount" },
        { acc: "111111111", amt: "30.00", acc_name: "*********ount" }
      ].to_json)
    end
  end

  describe '#success?' do
    it 'return true when status is 0 (approved)' do
      VCR.use_cassette('payway_v2_check_transaction_status_0') { subject.call }

      expect(subject.status).to eq '0'
      expect(subject.success?).to be true
    end

    it 'return false when status is not 0' do
      VCR.use_cassette('payway_v2_check_transaction_status_2') { subject.call }

      expect(subject.status).to eq '2'
      expect(subject.success?).to be false
    end
  end

  describe '#pending?' do
    it 'return true when status = 1 (create)' do
      VCR.use_cassette('payway_v2_check_transaction_status_1') { subject.call }

      expect(subject.status).to eq '1'
      expect(subject.pending?).to be true
    end

    it 'return true when status = 2 (pending)' do
      VCR.use_cassette('payway_v2_check_transaction_status_2') { subject.call }

      expect(subject.status).to eq '2'
      expect(subject.pending?).to be true
    end

    it 'return false when status is not 1 or 2' do
      allow(subject).to receive(:status).and_return('3')

      expect(subject.status).to eq '3'
      expect(subject.pending?).to be false
    end
  end

  describe '#failed?' do
    it 'return true when status is 3: Declined, 4: Refunded, 5: Wrong Hash' do
      allow(subject).to receive(:status).and_return('3')
      expect(subject.failed?).to be true

      allow(subject).to receive(:status).and_return('4')
      expect(subject.failed?).to be true

      allow(subject).to receive(:status).and_return('5')
      expect(subject.failed?).to be true
    end
  end

  describe '#build_payout_profile_payments' do
    let!(:existing_payout_profile) { create(:payway_payout_profile, bank_account_number: '070486124') }

    before do
      VCR.use_cassette('payway_v2_check_transaction_status_0') { subject.call }
    end

    let(:payout_profile_payments) {  subject.build_payout_profile_payments }

    it 'build payout profile payments base on payout response' do
      expect(subject.json_response['payout'].to_json).to eq([
        { acc: "070486124", amt: "25.00", acc_name: "*********ount" },
        { acc: "111111111", amt: "30.00", acc_name: "*********ount" }
      ].to_json)

      expect(payout_profile_payments.size).to eq 2
      expect(payout_profile_payments[0].amount).to eq 25
      expect(payout_profile_payments[1].amount).to eq 30
    end

    it 'find existing profile to build payout profile payment' do
      expect(payout_profile_payments[0].payout_profile.bank_account_number).to eq '070486124'
      expect(payout_profile_payments[0].payout_profile).to eq existing_payout_profile
    end

    it 'create new payout profile when not exist' do
      expect(payout_profile_payments[1].payout_profile.bank_account_number).to eq '111111111'
      expect(payout_profile_payments[1].payout_profile.name).to eq '*********ount'
      expect(payout_profile_payments[1].payout_profile.persisted?).to be true
      expect(payout_profile_payments[1].amount).to eq 30
    end
  end
end
