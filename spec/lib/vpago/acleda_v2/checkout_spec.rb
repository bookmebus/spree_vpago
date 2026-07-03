require 'spec_helper'

RSpec.describe Vpago::AcledaV2::Checkout do
  let(:order) { create(:order, number: 'R131576461') }
  let(:payment_method) { create(:acleda_v2_gateway) }
  let(:payment) do
    create(:acleda_v2_payment, number: 'PJ0MYD2Y', order: order, payment_method: payment_method, amount: 29.99)
  end
  let(:options) { {} }

  subject(:checkout) { described_class.new(payment, options) }

  let(:response_status) { 200 }
  let(:response_body) { { result: { code: 0 } }.to_json }
  let(:response) { instance_double(Faraday::Response, status: response_status, body: response_body) }

  before do
    allow(checkout).to receive(:open_session).and_return(response)
  end

  context 'when the session opens successfully' do
    let(:response_status) { 200 }
    let(:response_body) do
      {
        result: {
          code: 0,
          sessionid: 'sess-123',
          xTran: { paymentTokenid: 'tok-abc' }
        }
      }.to_json
    end

    describe '#call' do
      it 'is not failed' do
        checkout.call
        expect(checkout.failed?).to be false
      end

      it 'persists the paymentTokenid onto the payment source' do
        checkout.call
        expect(payment.source.reload.transaction_id).to eq('tok-abc')
      end
    end

    describe '#gateway_params' do
      before { checkout.call }

      it 'builds the paymentPage.jsp auto-POST form fields' do
        params = checkout.gateway_params

        expect(params[:sessionid]).to eq('sess-123')
        expect(params[:paymenttokenid]).to eq('tok-abc')
        expect(params[:transactionID]).to eq(payment.number)
        expect(params[:invoiceid]).to eq(order.number)
        expect(params[:successUrlToReturn]).to eq(payment.processing_url)
        expect(params[:errorUrl]).to eq(payment.processing_url)
      end
    end

    describe '#deeplink_url' do
      let(:response_body) do
        {
          result: {
            code: 0,
            deeplinkUrl: 'https://epaymentuat.acledabank.com.kh/deeplink',
            xTran: { paymentTokenid: 'tok-abc' }
          }
        }.to_json
      end

      it 'returns the bank deeplink url' do
        checkout.call
        expect(checkout.deeplink_url).to eq('https://epaymentuat.acledabank.com.kh/deeplink')
      end
    end
  end

  context 'when the bank returns a 500 with a raw error body' do
    let(:response_status) { 500 }
    let(:response_body) { 'Invalid parameter: txid' }

    it 'is failed and surfaces the raw body as the error message' do
      checkout.call

      expect(checkout.failed?).to be true
      expect(checkout.error_message).to eq('Invalid parameter: txid')
    end

    it 'returns empty gateway_params and a nil deeplink_url' do
      checkout.call

      expect(checkout.gateway_params).to eq({})
      expect(checkout.deeplink_url).to be_nil
    end

    it 'does not persist a transaction_id' do
      checkout.call

      expect(payment.source.reload.transaction_id).to be_nil
    end
  end

  context 'when the bank returns an unexpected HTTP status' do
    let(:response_status) { 404 }
    let(:response_body) { '' }

    it 'is failed with a generic Server Error message' do
      checkout.call

      expect(checkout.failed?).to be true
      expect(checkout.error_message).to eq('Server Error')
    end
  end

  context 'when the bank returns 200 with a non-zero result code' do
    let(:response_status) { 200 }
    let(:response_body) { { result: { code: 1, errorDetails: 'INVALID_HASH' } }.to_json }

    it 'is failed with the bank error details' do
      checkout.call

      expect(checkout.failed?).to be true
      expect(checkout.error_message).to eq('INVALID_HASH')
    end
  end

  describe '#open_session_payload (private) xpayTransaction per mode/platform' do
    subject(:xpay_transaction) { checkout.send(:open_session_payload)[:xpayTransaction] }

    context 'with the default khqr payment method' do
      it 'sends paymentCard "0" and no oprDevice/callBackUrl' do
        expect(xpay_transaction[:paymentCard]).to eq('0')
        expect(xpay_transaction).not_to have_key(:oprDevice)
        expect(xpay_transaction).not_to have_key(:callBackUrl)
      end
    end

    context 'with a card payment method' do
      let(:payment_method) { create(:acleda_v2_gateway, preferred_acleda_v2_mode: 'card') }

      it 'sends paymentCard "1"' do
        expect(xpay_transaction[:paymentCard]).to eq('1')
      end
    end

    context 'with a deeplink payment method opened from the app' do
      let(:payment_method) { create(:acleda_v2_gateway, preferred_acleda_v2_mode: 'deeplink') }
      let(:options) { { platform: 'app', opr_device: 'ios' } }

      it 'sends oprDevice/callBackUrl and no paymentCard' do
        expect(xpay_transaction[:oprDevice]).to eq('ios')
        expect(xpay_transaction[:callBackUrl]).to eq(payment.processing_url)
        expect(xpay_transaction).not_to have_key(:paymentCard)
      end

      context 'and the payment method has an app_scheme configured' do
        let(:payment_method) do
          create(:acleda_v2_gateway, preferred_acleda_v2_mode: 'deeplink', preferred_app_scheme: 'bookmeplus')
        end

        it 'sends callBackUrl as a bookmeplus:// deeplink instead of https://' do
          expect(xpay_transaction[:callBackUrl]).to start_with('bookmeplus://')
          expect(xpay_transaction[:callBackUrl]).not_to start_with('http')
        end
      end
    end

    context 'with a deeplink payment method opened from the web' do
      let(:payment_method) { create(:acleda_v2_gateway, preferred_acleda_v2_mode: 'deeplink') }
      let(:options) { { platform: 'web' } }

      it 'falls back to the KHQR paymentCard payload' do
        expect(xpay_transaction[:paymentCard]).to eq('0')
        expect(xpay_transaction).not_to have_key(:oprDevice)
        expect(xpay_transaction).not_to have_key(:callBackUrl)
      end
    end
  end
end
