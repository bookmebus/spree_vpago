require 'spec_helper'

RSpec.describe Vpago::TrueMoney::TransactionStatus do
  let(:order) { create(:order, number: 'R131576461') }
  let(:payment_method) { create(:true_money_gateway) }
  let(:payment) { create(:true_money_payment, number: 'PTTV6Z2O', order: order, payment_method: payment_method, amount: 0.10) }

  subject(:transaction_status) { described_class.new(payment) }

  let(:mock_access_token_response) do
    instance_double(Faraday::Response, success?: true, status: 200, body: { access_token: 'fake-token' }.to_json)
  end

  let(:mock_transaction_response_body) do
    {
      status: { code: '000001', message: 'success' },
      data: { external_ref_id: 'PTTV6Z2O', psp_amount: 0.10 }
    }.to_json
  end

  let(:mock_transaction_response) { instance_double(Faraday::Response, body: mock_transaction_response_body) }

  let(:connection) do
    instance_double(Faraday::Connection, post: mock_access_token_response, get: mock_transaction_response)
  end

  before do
    allow(Faraday).to receive(:new).and_return(connection)
    allow(Time).to receive(:now).and_return(Time.at(1_700_000_000))
    allow_any_instance_of(Vpago::RsaHandler).to receive(:generate_signature).and_return('dummy-signature')
  end

  describe '#call' do
    before { transaction_status.call }

    it 'returns a 000001 status code' do
      expect(transaction_status.response_code).to eq '000001'
    end

    it 'returns success? as true' do
      expect(transaction_status.success?).to be true
    end

    it 'returns a full json response with expected fields' do
      json = transaction_status.json_response
      expect(json['status']['message']).to eq 'success'
      expect(json['data']['external_ref_id']).to eq 'PTTV6Z2O'
      expect(json['data']['psp_amount']).to eq 0.10
    end
  end
end

