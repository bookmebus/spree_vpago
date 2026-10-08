require 'spec_helper'

RSpec.describe Vpago::AcledaMiniApp::SessionHashValidator do
  let(:secret_key) { 'test-secret' }
  let(:options) { { phone: '012345678', first_name: 'LyZing', last_name: 'Seak', hash: hash, secret_key: secret_key } }
  let(:hash) { OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret_key, '012345678LyZingSeak') }

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
      let(:secret_key) { nil }
      let(:hash) { 'a-signature-computed-somewhere-else' }

      it 'returns false' do
        expect(described_class.new(options).call).to be false
      end
    end
  end
  # The key lives only on ACLEDA's Spree::OauthApplication, so it can be rotated from the admin and
  # clearing it revokes the mini app rather than falling through to ENV.
  describe 'secret_key' do
    it 'uses the key it was given' do
      expect(described_class.new(secret_key: 'row-key').secret_key).to eq 'row-key'
    end

    it 'has none when the row carries none, and reads no other source' do
      expect(ENV).not_to receive(:fetch).with('ACLEDA_MINI_APP_SECRET_HASH_KEY', anything)

      expect(described_class.new(secret_key: nil).secret_key).to be_nil
      expect(described_class.new(secret_key: '').secret_key).to be_nil
      expect(described_class.new({}).secret_key).to be_nil
    end

    # Nothing to compare against must never read as a match.
    it 'refuses every signature when the row carries no key' do
      expect(described_class.new(secret_key: '', hash: 'anything').call).to be false
    end
  end
end
