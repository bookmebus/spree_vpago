require 'spec_helper'

RSpec.describe Vpago::AcledaV2::TransactionStatus do
  let(:order) { create(:order, number: 'R131576461') }
  let(:payment_method) { create(:acleda_v2_gateway) }
  let(:source) { create(:acleda_payment_source, transaction_id: 'tok-abc') }
  let(:payment) do
    create(:acleda_v2_payment, number: 'PJ0MYD2Y', order: order, payment_method: payment_method, source: source,
                               amount: 29.99)
  end

  subject(:transaction_status) { described_class.new(payment) }

  let(:response_status) { 200 }
  let(:response_body) { { result: { code: 0, errorDetails: 'SUCCESS' } }.to_json }
  let(:response) { instance_double(Faraday::Response, status: response_status, body: response_body) }

  before do
    allow(transaction_status).to receive(:check_remote_status).and_return(response)
  end

  describe '#call' do
    it 'stores the response and exposes result_code/error_message' do
      transaction_status.call

      expect(transaction_status.result_code).to eq(0)
      expect(transaction_status.error_message).to eq('SUCCESS')
    end
  end

  describe '#payload (private)' do
    it 'sends the paymentTokenid and merchant credentials to getTxnStatus' do
      payload = transaction_status.send(:payload)

      expect(payload[:paymentTokenid]).to eq('tok-abc')
      expect(payload[:loginId]).to eq(payment_method.preferred_login_id)
      expect(payload[:merchantId]).to eq(payment_method.preferred_merchant_id)
      expect(payload[:merchantName]).to eq(payment_method.preferred_merchant_name)
      expect(payload[:hash]).to eq(transaction_status.send(:txn_status_hash, 'tok-abc'))
    end
  end

  describe '#success?' do
    context 'when the token, http status, code and errorDetails all indicate success' do
      let(:response_status) { 200 }
      let(:response_body) { { result: { code: 0, errorDetails: 'SUCCESS' } }.to_json }

      it 'returns true' do
        transaction_status.call
        expect(transaction_status.success?).to be true
      end
    end

    context 'when the payment source has no token yet' do
      let(:source) { create(:acleda_payment_source, transaction_id: nil) }

      it 'returns false without needing the response' do
        transaction_status.call
        expect(transaction_status.success?).to be false
      end
    end

    context 'when the result code is non-zero' do
      let(:response_body) { { result: { code: 1, errorDetails: 'SUCCESS' } }.to_json }

      it 'returns false' do
        transaction_status.call
        expect(transaction_status.success?).to be false
      end
    end

    context 'when the HTTP request itself failed' do
      let(:response_status) { 500 }

      it 'returns false' do
        transaction_status.call
        expect(transaction_status.success?).to be false
      end
    end
  end

  describe '#failed?' do
    %w[EXPIRED DECLINED CANCELLED FAILED REJECTED].each do |detail|
      context "when errorDetails is #{detail}" do
        let(:response_body) { { result: { code: 1, errorDetails: detail } }.to_json }

        it 'returns true' do
          transaction_status.call
          expect(transaction_status.failed?).to be true
        end
      end
    end

    context 'when errorDetails is a non-terminal value' do
      let(:response_body) { { result: { code: 1, errorDetails: 'PENDING' } }.to_json }

      it 'returns false' do
        transaction_status.call
        expect(transaction_status.failed?).to be false
      end
    end

    context 'when the payment source has no token yet' do
      let(:source) { create(:acleda_payment_source, transaction_id: nil) }
      let(:response_body) { { result: { code: 1, errorDetails: 'DECLINED' } }.to_json }

      it 'returns false without needing the response' do
        transaction_status.call
        expect(transaction_status.failed?).to be false
      end
    end

    context 'when the HTTP request itself failed' do
      let(:response_status) { 500 }
      let(:response_body) { { result: { code: 1, errorDetails: 'DECLINED' } }.to_json }

      it 'returns false' do
        transaction_status.call
        expect(transaction_status.failed?).to be false
      end
    end
  end

  describe '#pending?' do
    context 'when neither successful nor terminally failed' do
      let(:response_body) { { result: { code: 1, errorDetails: 'PENDING' } }.to_json }

      it 'returns true' do
        transaction_status.call
        expect(transaction_status.pending?).to be true
      end
    end

    context 'when successful' do
      let(:response_body) { { result: { code: 0, errorDetails: 'SUCCESS' } }.to_json }

      it 'returns false' do
        transaction_status.call
        expect(transaction_status.pending?).to be false
      end
    end

    context 'when terminally failed' do
      let(:response_body) { { result: { code: 1, errorDetails: 'DECLINED' } }.to_json }

      it 'returns false' do
        transaction_status.call
        expect(transaction_status.pending?).to be false
      end
    end
  end
end
