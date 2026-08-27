require 'spec_helper'

RSpec.describe Vpago::Vattanac::Base do
  let(:order) { create(:order, number: 'R131576461') }
  let(:payment) { create(:vattanac_payment, number: 'PJ0MYD2Y', order: order) }
  let(:instance) { described_class.new(payment) }

  describe 'preferences accessors' do
    it 'reads username, password, urls, merchant and payment type from payment method' do
      pm = payment.payment_method
      expect(instance.username).to eq(pm.preferred_username)
      expect(instance.password).to eq(pm.preferred_password)
      expect(instance.access_token_url).to eq(pm.preferred_access_token_url)
      expect(instance.generate_payment_url).to eq(pm.preferred_generate_payment_url)
      expect(instance.check_transaction_url).to eq(pm.preferred_check_transaction_url)
      expect(instance.merchant_id).to eq(pm.preferred_merchant_id)
      expect(instance.payment_type).to eq(pm.preferred_payment_type)
    end

    it 'exposes payment_number, amount and currency' do
      expect(instance.payment_number).to eq(payment.number)
      expect(instance.amount).to eq(payment.amount)
      expect(instance.currency).to eq('USD')
    end
  end

  describe '#default_headers' do
    it 'adds Bearer token and JSON content-type' do
      allow(instance).to receive(:access_token).and_return('abc123')
      expect(instance.default_headers).to eq(
        'Authorization' => 'Bearer abc123',
        'Content-Type' => 'application/json'
      )
    end
  end


  describe '#access_token / fetch_access_token' do
    let(:token_url) { payment.payment_method.preferred_access_token_url }

    it 'fetches token from API and memoizes it on success' do
      success_response = double('Response', success?: true, status: 200, body: { data: { accessToken: 'tok-xyz' } }.to_json)
      connection = instance_double(Faraday::Connection)
      allow(Faraday).to receive(:new).and_return(connection)
      expect(connection).to receive(:post).with(
        token_url,
        { username: instance.username, password: instance.password }.to_json,
        { 'Content-Type' => 'application/json' }
      ).and_return(success_response)

      first = instance.access_token
      second = instance.access_token
      expect(first).to eq('tok-xyz')
      expect(second).to eq('tok-xyz') # memoized
    end

    it 'raises error when HTTP is not successful' do
      error_response = double('Response', success?: false, status: 401, body: 'unauthorized')
      connection = instance_double(Faraday::Connection, post: error_response)
      allow(Faraday).to receive(:new).and_return(connection)

      expect { instance.send(:fetch_access_token) }.to raise_error(RuntimeError, /Access Token Error: 401 - unauthorized/)
    end

    it 'raises error when accessToken is missing' do
      success_response = double('Response', success?: true, status: 200, body: { data: { } }.to_json)
      connection = instance_double(Faraday::Connection, post: success_response)
      allow(Faraday).to receive(:new).and_return(connection)

      expect { instance.send(:fetch_access_token) }.to raise_error(RuntimeError, /Missing accessToken/)
    end
  end

  describe '#post' do
    before { allow(instance).to receive(:access_token).and_return('abc123') }

    it 'posts through a connection configured with the open/read timeouts' do
      response = double('Response', body: { data: { status: 'SUCCESS' } }.to_json)
      connection = instance_double(Faraday::Connection, post: response)

      expect(Faraday).to receive(:new).with(
        request: { open_timeout: Vpago::HttpTimeouts::OPEN_TIMEOUT, timeout: Vpago::HttpTimeouts::TIMEOUT }
      ).and_return(connection)

      expect(instance.send(:post, 'https://example.com/check', { transactionId: 'X' })).to eq({ 'data' => { 'status' => 'SUCCESS' } })
    end

    it 'propagates a Faraday timeout raised by the underlying connection' do
      allow(Faraday).to receive(:new).and_raise(Faraday::TimeoutError)

      expect { instance.send(:post, 'https://example.com/check', { transactionId: 'X' }) }.to raise_error(Faraday::TimeoutError)
    end
  end
end
