require 'spec_helper'
require 'vcr'

RSpec.describe Vpago::PaywayV2::PreAuthCompleter do

  let(:payment_method) { create(:payway_v2_gateway) }
  let(:payment) { create(:payway_v2_payment, payment_method: payment_method) }
  let(:mocked_merchant_auth_encryption) { 'mocked_encrypted_value' }


  subject { described_class.new(payment) }

  before do
    allow(subject).to receive(:complete_url).and_return('https://checkout-sandbox.payway.com.kh/api/merchant-portal/merchant-access/online-transaction/pre-auth-completion')
    allow(subject).to receive(:merchant_auth_encryption).and_return(mocked_merchant_auth_encryption) 
  end

  describe '#connection' do
    it 'times out instead of holding the worker for the Net::HTTP defaults' do
      options = subject.connection.options

      expect(options.open_timeout).to eq Vpago::HttpTimeouts::OPEN_TIMEOUT
      expect(options.timeout).to eq Vpago::HttpTimeouts::TIMEOUT
    end
  end

  describe '#call' do 
    it 'successfully collect the amount' do 
      expect(subject).to receive(:pre_auth_response).and_call_original

      VCR.use_cassette('payway_v2_pre_auth_completer_status_0') do
        subject.call
      end

      response = subject.json_response

      expect(subject.success?).to eq true 
      expect(subject.merchant_auth).not_to include('"payout"')
      expect(response['transaction_status']).to eq 'COMPLETED' 
      expect(response['status']['message']).to eq 'Success!'
    end

    it 'failed when transaction_id is invalid' do 
      VCR.use_cassette('payway_v2_pre_auth_completer_invalid_transaction') do
        subject.call
      end

      response = subject.json_response

      expect(subject.success?).to eq false 
      expect(response['status']['message']).to eq 'Invalid Transaction' 
    end

    it 'failed when the amount is already collect' do 
      VCR.use_cassette('payway_v2_pre_auth_completer_amount_already_collect') do
        subject.call
      end
      
      response = subject.json_response

      expect(subject.success?).to eq false 
      expect(response['status']['message']).to eq 'Unable to complete or cancel Pre Auth' 
    end

    context 'when the gateway returns a non-JSON body' do
      before do
        allow(subject).to receive(:pre_auth_response).and_return(instance_double(Faraday::Response, body: '<html>502 Bad Gateway</html>', status: 502))
      end

      it 'is a failure instead of raising, and keeps the raw body for the log' do
        subject.call

        expect(subject.success?).to eq false
        expect(subject.json_response).to eq('raw_body' => '<html>502 Bad Gateway</html>', 'http_status' => 502)
      end
    end

    context 'when the gateway returns JSON without a status object' do
      before do
        allow(subject).to receive(:pre_auth_response).and_return(instance_double(Faraday::Response, body: '{"status":"error"}', status: 500))
      end

      it 'is a failure instead of raising' do
        subject.call

        expect(subject.success?).to eq false
      end
    end

    context 'when payout is enabled' do
      before do
        allow_any_instance_of(Vpago::PaywayV2::PayoutsParamsConstructor).to receive(:call).and_return([
          {:acc=>"002092768", :amt=>"27.00"},
          {:acc=>"111111111", :amt=>"3.00"}
        ])
      end

      it 'successfully collect the amount with payout' do 
        expect(subject).to receive(:pre_auth_response).and_call_original

        VCR.use_cassette('payway_v2_pre_auth_completer_with_payout') do
          subject.call
        end

        response = subject.json_response

        expect(subject.merchant_auth).to include('"payout"') # contains payout params
        expect(response['transaction_status']).to eq 'COMPLETED' 
        expect(response['status']['message']).to eq 'Success!' 
      end
    end
  end
end
