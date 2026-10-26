require 'spec_helper'

RSpec.describe Vpago::AcledaMiniApp::Checkout do
  let(:order) { create(:order, number: 'R131576461') }
  let(:payment_method) { create(:acleda_mini_app_gateway) }
  let(:payment) do
    create(:acleda_mini_app_payment, number: 'PJ0MYD2Y', order: order, payment_method: payment_method, amount: 29.99)
  end

  subject(:checkout) { described_class.new(payment, { platform: 'app', opr_device: 'android' }) }

  let(:response_body) do
    {
      result: {
        code: 0,
        deeplinkUrl: 'https://epaymentuat.acledabank.com.kh/deeplink',
        xTran: { paymentTokenid: 'tok-abc' }
      }
    }.to_json
  end
  let(:response) { instance_double(Faraday::Response, status: 200, body: response_body) }

  before do
    allow(checkout).to receive(:open_session).and_return(response)
  end

  it 'always runs in deeplink mode regardless of gateway config' do
    expect(checkout.deeplink?).to be true
  end

  describe '#acleda_deeplink' do
    it 'returns the openSessionV2 deeplink url' do
      expect(checkout.acleda_deeplink).to eq('https://epaymentuat.acledabank.com.kh/deeplink')
    end

    it 'opens the session only once even when called repeatedly' do
      checkout.acleda_deeplink
      checkout.acleda_deeplink
      expect(checkout).to have_received(:open_session).once
    end

    it 'persists the paymentTokenid for later getTxnStatus verification' do
      checkout.acleda_deeplink
      expect(payment.source.reload.transaction_id).to eq('tok-abc')
    end
  end
end
