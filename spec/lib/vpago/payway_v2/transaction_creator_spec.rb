require 'spec_helper'

RSpec.describe Vpago::PaywayV2::TransactionCreator do
  let!(:default_payout_profile) { create(:payway_payout_profile, active: true, bank_account_number: '333', default: true, verified_at: DateTime.current) }

  let(:payment_method) { create(:payway_v2_gateway) }
  let(:payment) { create(:payment, payment_method: payment_method) }

  subject { described_class.new(payment) }

  before do
    allow(subject).to receive(:hash_hmac).and_return('fake_hash_hmac')
  end

  describe '#call' do
    it 'posts gateway_params to checkout_url and saves the response' do
      response = double(status: 200, body: '{"status":{"code":0},"abapay_deeplink":"aba://pay","checkout_qr_url":"https://qr"}')
      allow_any_instance_of(Faraday::Connection).to receive(:post).with(subject.checkout_url, subject.gateway_params).and_return(response)

      subject.call

      expect(subject.json_response).to eq(
        'status' => { 'code' => 0 },
        'abapay_deeplink' => 'aba://pay',
        'checkout_qr_url' => 'https://qr'
      )
    end

    it 'configures the connection with the shared open/read timeouts' do
      allow(Faraday::Connection).to receive(:new).and_wrap_original do |original, *args, &block|
        conn = original.call(*args, &block)

        expect(conn.options.open_timeout).to eq Vpago::HttpTimeouts::OPEN_TIMEOUT
        expect(conn.options.timeout).to eq Vpago::HttpTimeouts::TIMEOUT

        allow(conn).to receive(:post).and_return(double(status: 200, body: '{}'))
        conn
      end

      subject.call
    end

    it 'propagates a Faraday timeout raised by the underlying connection' do
      allow_any_instance_of(Faraday::Connection).to receive(:post).and_raise(Faraday::TimeoutError)

      expect { subject.call }.to raise_error(Faraday::TimeoutError)
    end
  end

  describe '#json_response' do
    it 'returns an empty hash when the response body is not valid JSON' do
      allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(double(status: 200, body: 'not json'))

      subject.call

      expect(subject.json_response).to eq({})
    end
  end
end
