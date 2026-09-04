require 'spec_helper'

RSpec.describe Vpago::PaywayV2::TransactionStatusV2 do
  let!(:default_payout_profile) { create(:payway_payout_profile, active: true, bank_account_number: '333', default: true, verified_at: DateTime.current)}

  let(:payment_method) { create(:payway_v2_gateway) }
  let(:payment) { create(:payment, payment_method: payment_method) }

  subject { described_class.new(payment) }

  before do
    allow(subject).to receive(:check_transaction_url).and_return('https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/check-transaction-2')
  end

  describe '#call' do
    it 'call request to check_remote_status & save to response' do
      expect(subject).to receive(:check_remote_status).and_call_original

      VCR.use_cassette('payway_v2_check_transaction_status_v2_approved') do
        subject.call
      end

      expect(subject.json_response).to be_a Hash
      expect(subject.json_response['status']['code']).to eq '00'
      expect(subject.json_response['data']['payment_status']).to eq 'APPROVED'
    end
  end

  describe '#success?' do
    it 'return true when status is PRE-AUTH' do
      VCR.use_cassette('payway_v2_check_transaction_status_v2_pre_auth') { subject.call }

      expect(subject.payment_status).to eq 'PRE-AUTH'
      expect(subject.success?).to be true
    end

    it 'return false when status is not PRE-AUTH or APPROVED' do
      VCR.use_cassette('payway_v2_check_transaction_status_v2_pending') { subject.call }

      expect(subject.payment_status).to eq 'PENDING'
      expect(subject.success?).to be false
    end
  end

  describe '#pending?' do
    it 'return true when status = PENDING' do
      VCR.use_cassette('payway_v2_check_transaction_status_v2_pending') { subject.call }

      expect(subject.payment_status).to eq 'PENDING'
      expect(subject.pending?).to be true
    end
  end

  describe '#failed?' do
    it 'return true when status 5 : Invalid hash or 6 : Transaction not found or 8 : Invalid merchant profile' do
      allow(subject).to receive(:status_code).and_return('5')
      expect(subject.failed?).to be true

      allow(subject).to receive(:status_code).and_return('6')
      expect(subject.failed?).to be true

      allow(subject).to receive(:status_code).and_return('8')
      expect(subject.failed?).to be true
    end

    it 'return true when payment_status is DECLINED or CANCELLED' do
      allow(subject).to receive(:status_code).and_return('00')
      allow(subject).to receive(:payment_status).and_return('DECLINED')
      expect(subject.failed?).to be true

      allow(subject).to receive(:status_code).and_return('00')
      allow(subject).to receive(:payment_status).and_return('CANCELLED')
      expect(subject.failed?).to be true
    end
  end

  describe '#error_message' do
    it 'return error message when status code is 5, 6, or 8' do
      VCR.use_cassette('payway_v2_check_transaction_status_v2_invalid_hash') { subject.call }

      expect(subject.status_code).to eq '5'
      expect(subject.error_message).to eq 'wrong hash'
    end
  end

  describe '#check_remote_status' do
    it 'configures the connection with the shared open/read timeouts' do
      allow(Faraday::Connection).to receive(:new).and_wrap_original do |original, *args, &block|
        conn = original.call(*args, &block)

        expect(conn.options.open_timeout).to eq Vpago::HttpTimeouts::OPEN_TIMEOUT
        expect(conn.options.timeout).to eq Vpago::HttpTimeouts::TIMEOUT

        allow(conn).to receive(:post).and_return(double(status: 200, body: '{}'))
        conn
      end

      subject.send(:check_remote_status)
    end

    it 'propagates a Faraday timeout raised by the underlying connection' do
      allow_any_instance_of(Faraday::Connection).to receive(:post).and_raise(Faraday::TimeoutError)

      expect { subject.send(:check_remote_status) }.to raise_error(Faraday::TimeoutError)
    end
  end
end
