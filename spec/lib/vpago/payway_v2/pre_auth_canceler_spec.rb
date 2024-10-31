require 'spec_helper'
require 'vcr'

RSpec.describe Vpago::PaywayV2::PreAuthCanceler do

  let(:payment_method) { create(:payway_v2_gateway) }
  let(:payment) { create(:payway_v2_payment, payment_method: payment_method) }
  let(:mocked_merchant_auth_encryption) { 'mocked_encrypted_value' }

  subject { described_class.new(payment) }

  before do
    allow(subject).to receive(:cancel_url).and_return('https://checkout-sandbox.payway.com.kh/api/merchant-portal/merchant-access/online-transaction/pre-auth-cancellation')
    allow(subject).to receive(:merchant_auth_encryption).and_return(mocked_merchant_auth_encryption) 
  end

  describe '#call' do 
    it 'successfully cancel the hold amount' do 
      expect(subject).to receive(:pre_auth_response).and_call_original

      VCR.use_cassette('payway_v2_pre_auth_canceler_status_0') do
        subject.call
      end

      response = payment.pre_auth_response

      expect(subject.success?).to eq true
      expect(response['transaction_status']).to eq 'CANCELLED' 
      expect(response['status']['message']).to eq 'Success!'
    end

    it 'failed when transaction_id is invalid' do 
      VCR.use_cassette('payway_v2_pre_auth_canceler_invalid_transaction') do
        subject.call
      end

      response = payment.pre_auth_response

      expect(subject.success?).to eq false 
      expect(response['status']['message']).to eq 'Invalid Transaction' 
    end

    it 'failed when the amount is already cancel' do 
      VCR.use_cassette('payway_v2_pre_auth_cancelor_amount_already_collect') do
        subject.call
      end

      response = payment.pre_auth_response

      expect(subject.success?).to eq false 
      expect(response['status']['message']).to eq 'Unable to complete or cancel Pre Auth' 
    end
  end
end
