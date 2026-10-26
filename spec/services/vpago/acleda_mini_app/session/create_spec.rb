require 'spec_helper'

RSpec.describe Vpago::AcledaMiniApp::Session::Create do
  # Stand-ins for SpreeCmCommissioner::MiniAppProvider::SessionGate and its mini app, neither
  # loadable here: spree_cm_commissioner depends on spree_vpago, never the other way round.
  # The gate's own behaviour is covered by its spec in that gem.
  let(:mini_app) { double('MiniAppProvider::AcledaBank', preferred_secret_key: secret) }
  let(:gate) do
    double(
      'MiniAppProvider::SessionGate',
      api_key_accepted?: true, address_allowed?: true, mini_app: mini_app,
      session_exceeded?: false, new_user_exceeded?: false
    )
  end

  let(:secret) { 'the-key-acleda-signs-with' }
  let(:payload) { { phone: '012345678', first_name: 'Sam', last_name: 'Bo' } }

  # Same reason: the parser lives in spree_cm_commissioner. Only the guards past the
  # signature reach it.
  before do
    stub_const(
      'SpreeCmCommissioner::PhoneNumberParser',
      double('PhoneNumberParser', call: double('parsed', intel_phone_number: '+85512345678'))
    )
  end

  def signature(key)
    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha256'), key, "#{payload[:phone]}#{payload[:first_name]}#{payload[:last_name]}"
    )
  end

  def create_session(**overrides)
    described_class.call(**payload, signature: signature(secret), gate: gate, **overrides)
  end

  # Each guard is proven by the status it answers with, and by reaching the signature check —
  # which is what shows the guards before it let the call through.
  describe 'the gate' do
    it 'refuses a caller whose api key the gate does not accept' do
      allow(gate).to receive(:api_key_accepted?).and_return(false)

      result = create_session

      expect(result).to be_failure
      expect(result.error.to_s).to eq 'missing or unknown api key'
      expect(result.value[:status]).to eq :unauthorized
    end

    it 'refuses an address the gate does not allow' do
      allow(gate).to receive(:address_allowed?).and_return(false)

      result = create_session

      expect(result.error.to_s).to eq 'address not allowed'
      expect(result.value[:status]).to eq :forbidden
    end

    # After the signature, never before: a trip here is correctly signed traffic flooding us.
    it 'refuses a caller past its cap, by the normalized phone' do
      expect(gate).to receive(:session_exceeded?).with(phone: '+85512345678').and_return(true)

      result = create_session

      expect(result.error.to_s).to eq 'too many requests'
      expect(result.value[:status]).to eq :too_many_requests
    end

    it 'lets an identified caller through to the signature' do
      expect(create_session(signature: 'not-the-signature').error.to_s).to eq 'invalid signature'
    end
  end

  describe 'the signing key' do
    # Rotating it on the application changes what the endpoint accepts, with no deploy and no ENV
    # change: the signature that was valid a moment ago no longer is.
    it 'verifies against the key the gate found, not ENV' do
      allow(mini_app).to receive(:preferred_secret_key).and_return('rotated-key')

      expect(create_session(signature: signature(secret)).error.to_s).to eq 'invalid signature'
    end

    # An unconfigured mini app still has to sign — there is just no key on a row to check
    # against, so SessionHashValidator falls back to ENV.
    it 'still enforces the signature with no application row' do
      allow(gate).to receive(:mini_app).and_return(nil)

      expect(create_session(signature: 'not-the-signature').error.to_s).to eq 'invalid signature'
    end
  end

  it 'still refuses a blank phone before anything else' do
    expect(gate).not_to receive(:api_key_accepted?)

    expect(create_session(phone: '').error.to_s).to eq 'phone is required'
  end
end
