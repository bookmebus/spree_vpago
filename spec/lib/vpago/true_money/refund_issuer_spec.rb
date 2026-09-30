require 'spec_helper'

RSpec.describe Vpago::TrueMoney::RefundIssuer do
  let(:order) { create(:order, number: 'R131576461') }
  let(:payment_method) { create(:true_money_gateway) }
  let(:payment) do
    create(:true_money_payment,
           number: 'PVTZ3SVH',
           order: order,
           payment_method: payment_method,
           amount: 0.10)
  end

  subject(:refund_issuer) { described_class.new(payment) }

  let(:mock_access_token_response) do
    instance_double(Faraday::Response, success?: true, status: 200, body: { access_token: 'fake-token' }.to_json)
  end

  let(:mock_refund_response_body) do
    <<~JSON
      {
        "status": {"code": "000001", "message": "Success"},
        "data": {
          "external_ref_id": "PVTZ3SVH",
          "transaction_id": "01250722093128295R0863604",
          "detail": {
            "transaction_id": "01250722093128295R0863604",
            "ref_transaction_id": "01250722092148469R7540260",
            "payment_command": "full_refund",
            "acquirer_transaction_id": "PVTZ3SVH",
            "amount": 0.10,
            "currency": "USD",
            "user_type": "CUSTOMER",
            "country_code": "KH",
            "psp_currency": "USD",
            "psp_amount": 0.10000,
            "payment_type": "RETAIL_PAYMENT",
            "status": 2,
            "state": 2
          }
        }
      }
    JSON
  end

  let(:mock_refund_response) do
    instance_double(Faraday::Response, success?: true, status: 200, body: mock_refund_response_body)
  end

  let(:token_connection) { instance_double(Faraday::Connection, post: mock_access_token_response) }

  before do
    allow(Faraday).to receive(:new).and_return(token_connection)
    allow(Faraday).to receive(:post).and_return(mock_refund_response)
    allow(Time).to receive(:now).and_return(Time.at(1_700_000_000))
    allow_any_instance_of(Vpago::RsaHandler).to receive(:generate_signature).and_return('dummy-signature')
  end

  describe '#call' do
    before { refund_issuer.call }

    it 'returns success' do
      expect(refund_issuer.success?).to be true
    end

    it 'has correct status code and message' do
      status = refund_issuer.parsed_response['status']
      expect(status['code']).to eq '000001'
      expect(status['message']).to eq 'Success'
    end

    it 'parses the external_ref_id and transaction_id' do
      data = refund_issuer.parsed_response['data']
      expect(data['external_ref_id']).to eq 'PVTZ3SVH'
      expect(data['transaction_id']).to eq '01250722093128295R0863604'
    end

    it 'parses refund detail correctly' do
      detail = refund_issuer.parsed_response['data']['detail']
      expect(detail['amount']).to eq 0.10
      expect(detail['currency']).to eq 'USD'
      expect(detail['user_type']).to eq 'CUSTOMER'
      expect(detail['country_code']).to eq 'KH'
      expect(detail['psp_amount']).to eq 0.10000
      expect(detail['payment_type']).to eq 'RETAIL_PAYMENT'
      expect(detail['status']).to eq 2
      expect(detail['state']).to eq 2
    end
  end
end
