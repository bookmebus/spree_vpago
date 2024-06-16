require 'spec_helper'

RSpec.describe Vpago::PayoutProfiles::Payway::PayoutProfileRequestParamsBuilder do
  let(:request_time) { DateTime.new(2024, 05, 07, 05, 33, 10) }
  let(:profile) { create(:payway_payout_profile, bank_account_number: '002094060') }

  subject { described_class.new(request_time, profile) }

  describe '#formatted_request_time' do
    it 'formatted date time according to payway document' do
      expect(subject.formatted_request_time).to eq '20240507053310'
    end
  end

  describe '#merchant_auth_data' do
    context 'when active true' do
      it 'return merchant auth data in json' do
        allow(profile).to receive(:active).and_return(true)

        expect(profile.preferred_merchant_id).to eq 'contigoasia'
        expect(profile.preferred_payee).to eq '002094060'
  
        expect(subject.merchant_auth_data).to eq ({
          "mc_id" => "contigoasia", 
          "payee" => "002094060",
          "status" => "1"
        }.to_json)
      end
    end

    context 'when active false' do
      it 'return merchant auth data in json' do
        allow(profile).to receive(:active).and_return(false)

        expect(profile.preferred_merchant_id).to eq 'contigoasia'
        expect(profile.preferred_payee).to eq '002094060'
  
        expect(subject.merchant_auth_data).to eq ({
          "mc_id" => "contigoasia", 
          "payee" => "002094060",
          "status" => "0"
        }.to_json)
      end
    end
  end

  describe '#merchant_auth' do
    it 'encrypt the merchant auth data' do
      expect(Vpago::PayoutProfiles::Payway::OpenSslEncrypter).to receive(:new).with(
        content: subject.merchant_auth_data,
        rsa_public_key: subject.rsa_public_key
      ).and_call_original

      expect(subject.merchant_auth.size).to eq 172
      expect(subject.merchant_auth).not_to eq(subject.merchant_auth_data)
    end
  end

  describe '#hash_data' do
    it 'return hash data in combine of request time & merchant auth' do
      formatted_request_time = subject.formatted_request_time
      merchant_auth = subject.merchant_auth

      expect(subject.hash_data).to eq "#{formatted_request_time}#{merchant_auth}"
    end
  end

  describe '#encoded_hash' do
    it 'hash with sha512 & encode with strict_encode64' do
      digest_name = OpenSSL::Digest.new('sha512')
      api_key = subject.api_key
      hash_data = subject.hash_data

      expect(OpenSSL::HMAC).to receive(:digest).with(digest_name, api_key, hash_data).and_call_original
      expect(Base64).to receive(:strict_encode64).with(any_args).and_call_original

      expect(subject.encoded_hash.size).to eq 88
    end
  end
end
