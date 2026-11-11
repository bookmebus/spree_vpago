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

  describe '#acleda_android_app_link' do
    def stub_deeplink(url)
      allow(checkout).to receive(:acleda_deeplink).and_return(url)
    end

    it 'builds the app address the deeplink landing page opens, carrying its query' do
      stub_deeplink('https://epayment.acledabank.com.kh/acleda?paymenttokenid=tok-abc&sessionid=s1')

      expect(checkout.acleda_android_app_link).to eq('https://com.domain.acledabankqr/app?paymenttokenid=tok-abc&sessionid=s1')
    end

    it 're-encodes the query the way the landing page does' do
      stub_deeplink('https://epayment.acledabank.com.kh/acleda?data=a%2Fb%3D%3D&name=a b')

      expect(checkout.acleda_android_app_link).to eq('https://com.domain.acledabankqr/app?data=a%2Fb%3D%3D&name=a+b')
    end

    it 'omits the query when the deeplink has none' do
      stub_deeplink('https://epayment.acledabank.com.kh/acleda')

      expect(checkout.acleda_android_app_link).to eq('https://com.domain.acledabankqr/app')
    end

    it 'is nil without a deeplink' do
      stub_deeplink(nil)

      expect(checkout.acleda_android_app_link).to be_nil
    end
  end
end
