require 'spec_helper'

RSpec.describe Vpago::AcledaMiniApp::SessionHashValidator do
  let(:secret_key) { 'test-secret' }
  let(:options) { { phone: '012345678', first_name: 'LyZing', last_name: 'Seak', hash: hash } }
  let(:hash) { OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret_key, '012345678LyZingSeak') }

  before { allow(ENV).to receive(:fetch).with('ACLEDA_MINI_APP_SECRET_HASH_KEY', nil).and_return(secret_key) }

  describe '#call' do
    context 'when the hash matches phone + first_name + last_name + secret' do
      it 'returns true' do
        expect(described_class.new(options).call).to be true
      end
    end

    context 'when the hash does not match' do
      let(:hash) { 'invalid-hash' }

      it 'returns false' do
        expect(described_class.new(options).call).to be false
      end
    end

    context 'when the hash is blank' do
      let(:hash) { nil }

      it 'returns false' do
        expect(described_class.new(options).call).to be false
      end
    end

    context 'when the secret key is not configured' do
      before { allow(ENV).to receive(:fetch).with('ACLEDA_MINI_APP_SECRET_HASH_KEY', nil).and_return(nil) }

      it 'returns false' do
        expect(described_class.new(options).call).to be false
      end
    end
  end
end
