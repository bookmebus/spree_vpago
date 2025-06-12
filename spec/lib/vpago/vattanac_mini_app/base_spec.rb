require 'spec_helper'

RSpec.describe Vpago::VattanacMiniApp::Base do
  let(:order) { create(:order, number: 'R131576461') }

  let(:payment) { create(:vattanac_mini_app_payment, number: 'PJ0MYD2Y', order: order) }
  let(:options) { {} }
  let(:instance) { described_class.new(payment, options) }

  let(:aes_key) { 'test_aes_key' }
  let(:private_key) { 'test_private_key' }
  let(:public_key) { 'test_public_key' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('VATTANAC_AES_SECRET_KEY').and_return(aes_key)
    allow(ENV).to receive(:[]).with('BOOKMEPLUS_PRIVATE_KEY').and_return(private_key)
    allow(ENV).to receive(:[]).with('VATTANAC_PUBLIC_KEY').and_return(public_key)
    allow(ENV).to receive(:[]).with('VATTANAC_PARTNER_CODE').and_return('partner123')
    allow(ENV).to receive(:[]).with('VATTANAC_REFUND_URL').and_return('https://refund.url')
  end

  describe '#partner_code' do
    it 'returns partner code from ENV' do
      expect(instance.partner_code).to eq('partner123')
    end
  end

  describe '#refund_url' do
    it 'returns refund url from ENV' do
      expect(instance.refund_url).to eq('https://refund.url')
    end
  end

  describe '#payload' do
    it 'returns correct payload structure' do
      result = instance.payload
      expect(result[:paymentId]).to eq(payment.number)
      expect(result[:amount]).to eq(payment.amount)
      expect(result[:currency]).to eq('USD')
      expect(result[:expiredIn]).to be_a(Integer)
    end
  end
end
