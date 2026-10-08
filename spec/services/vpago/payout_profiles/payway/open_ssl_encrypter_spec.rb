require 'spec_helper'

RSpec.describe Vpago::PayoutProfiles::Payway::OpenSslEncrypter do
  describe '#call' do
    let(:rsa_public_key) { OpenSSL::PKey::RSA.new(2048) }
    let(:content) { 'This is a test string to encrypt.' }
    let(:encrypter) { described_class.new(content: content, rsa_public_key: rsa_public_key.public_key) }

    it 'encrypts the content string' do
      encrypted_string = encrypter.call

      expect(encrypted_string).not_to be_empty
      expect(encrypted_string).not_to eq(content)
    end

    it 'encrypts with different result every call' do
      encrypted_string_1 = encrypter.call
      encrypted_string_2 = encrypter.call

      expect(encrypted_string_1).not_to be_empty
      expect(encrypted_string_2).not_to be_empty
      expect(encrypted_string_1).not_to eq(encrypted_string_2)
    end

    it 'decrypts the encrypted string back to original' do
      encrypted_string = encrypter.call
      decrypted_string = rsa_public_key.private_decrypt(Base64.strict_decode64(encrypted_string))

      expect(decrypted_string).to eq(content)
    end
  end
end
