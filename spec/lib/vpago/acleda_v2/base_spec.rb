require 'spec_helper'

RSpec.describe Vpago::AcledaV2::Base do
  let(:order) { create(:order) }
  let(:payment) { create(:acleda_v2_payment, order: order) }
  let(:options) { {} }

  subject(:base) { described_class.new(payment, options) }

  describe '#expiry_time' do
    context 'when the order has a hold with time remaining' do
      before { allow(order).to receive(:hold_expires_at).and_return(3.minutes.from_now + 10.seconds) }

      it 'returns the ceiled minutes left as a string' do
        expect(base.expiry_time).to eq('4')
      end
    end

    context 'when the order hold has already lapsed' do
      before { allow(order).to receive(:hold_expires_at).and_return(2.minutes.ago) }

      it 'falls back to the admin-configured preference' do
        expect(base.expiry_time).to eq('5')
      end
    end

    context 'when the order has a hold_expires_at of nil (no active hold)' do
      before { allow(order).to receive(:hold_expires_at).and_return(nil) }

      it 'falls back to the admin-configured preference' do
        expect(base.expiry_time).to eq('5')
      end
    end
  end

  describe '#callback_url' do
    context 'when not a deeplink checkout' do
      it 'returns the plain payment processing url' do
        expect(base.callback_url).to eq(payment.processing_url)
      end
    end

    context 'when a deeplink checkout opened from the app but no app_scheme is configured' do
      let(:payment_method) { create(:acleda_v2_gateway, preferred_acleda_v2_mode: 'deeplink') }
      let(:payment) { create(:acleda_v2_payment, order: order, payment_method: payment_method) }
      let(:options) { { platform: 'app' } }

      it 'returns the plain payment processing url' do
        expect(base.callback_url).to eq(payment.processing_url)
      end
    end

    # context 'when a deeplink checkout opened from the app with an app_scheme configured' do
    #   let(:payment_method) do
    #     create(:acleda_v2_gateway, preferred_acleda_v2_mode: 'deeplink', preferred_app_scheme: 'bookmeplusdev')
    #   end
    #   let(:payment) { create(:acleda_v2_payment, order: order, payment_method: payment_method) }
    #   let(:options) { { platform: 'app' } }

    #   it 'swaps the processing url scheme to the app scheme, so the bank app can hand control back natively' do
    #     uri = URI.parse(payment.processing_url)
    #     uri.scheme = 'bookmeplusdev'

    #     expect(base.callback_url).to eq(uri.to_s)
    #   end
    # end
  end
end
