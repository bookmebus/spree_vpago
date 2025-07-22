require 'spec_helper'

RSpec.describe Vpago::TrueMoney::Base do
  let(:order) { create(:order, number: 'R131576461') }
  let(:payment_method) { create(:true_money_gateway) }

  let(:payment) { create(:true_money_payment, number: 'PJ0MYD2Y', order: order, payment_method: payment_method, amount: 100) }
  let(:options) { {} }
  let(:instance) { described_class.new(payment, options) }

  describe '#client_id' do
    it 'returns client id from payment method' do
      expect(instance.client_id).to eq 'test_client_id'
    end
  end

  describe '#client_secret' do
    it 'returns client secret from payment method' do
      expect(instance.client_secret).to eq 'test_client_secret'
    end
  end

  describe '#private_key' do
    it 'returns private key from payment method' do
      expect(instance.private_key).to eq 'test_private_key'
    end
  end

  describe '#external_ref_id' do
    it 'returns payment number' do
      expect(instance.external_ref_id).to eq payment.number
    end
  end

  describe '#payload' do
    it 'returns correct payload hash' do
      expect(instance.payload).to eq({
        service_type: '01',
        external_ref_id: payment.number,
        amount: payment.amount,
        currency: 'USD',
        user_type: 'CUSTOMER'
      })
    end
  end

  describe '#default_headers' do
    before do
      allow(instance).to receive(:access_token).and_return('mock_access_token')
      allow(Vpago::RsaHandler).to receive_message_chain(:new, :generate_signature).and_return('mock_signature')
      allow(instance).to receive(:timestamp).and_return(1234567890)
    end

    it 'returns expected default headers' do
      expect(instance.default_headers).to eq({
        'Client-Id' => 'test_client_id',
        'Authorization' => 'Bearer mock_access_token',
        'Signature' => 'algorithm=rsa-sha256;keyVersion=1;signature=mock_signature',
        'Timestamp' => '1234567890',
        'Content-Type' => 'application/json'
      })
    end
  end

  describe '#check_transaction_url' do
    it 'returns correct check transaction URL' do
      expect(instance.check_transaction_url).to eq 'https://example.com/merchant/transactions/ext-ref/PJ0MYD2Y'
    end
  end

  describe '#fetch_access_token' do
    let(:token_response) { double('Response', success?: true, body: { access_token: 'access_token_123' }.to_json) }

    before do
      allow(Faraday).to receive(:post).and_return(token_response)
    end

    it 'returns the fetched access token' do
      expect(instance.fetch_access_token).to eq 'access_token_123'
    end

    context 'when response is not successful' do
      let(:token_response) { double('Response', success?: false, status: 401, body: 'Unauthorized') }

      it 'raises an error' do
        expect { instance.fetch_access_token }.to raise_error(RuntimeError, /Access Token Error: 401 - Unauthorized/)
      end
    end
  end

  describe '#parse_json' do
    it 'parses valid JSON' do
      expect(instance.parse_json('{"key": "value"}')).to eq({ 'key' => 'value' })
    end

    it 'returns empty hash on invalid JSON' do
      expect(instance.parse_json('invalid_json')).to eq({})
    end
  end

  describe '#signature_input' do
    before { allow(instance).to receive(:timestamp).and_return(1234567890) }

    it 'returns correct signature input' do
      expect(instance.signature_input).to eq("1234567890#{instance.payload.to_json}")
    end
  end
end
