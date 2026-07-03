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
    context 'when app_scheme is blank' do
      context 'and platform is app' do
        let(:options) { { platform: 'app' } }

        it 'returns the plain processing url unchanged' do
          expect(base.callback_url).to eq(base.continue_success_url)
        end
      end

      context 'and platform is web' do
        let(:options) { { platform: 'web' } }

        it 'returns the plain processing url unchanged' do
          expect(base.callback_url).to eq(base.continue_success_url)
        end
      end
    end

    context 'when app_scheme is present' do
      let(:payment) do
        create(:acleda_v2_payment, order: order,
                                    payment_method: create(:acleda_v2_gateway, preferred_app_scheme: 'bookmeplus'))
      end

      context 'and platform is app' do
        let(:options) { { platform: 'app' } }

        it 'swaps the scheme for the app scheme, preserving host/path/query' do
          expected = URI.parse(base.continue_success_url).tap { |uri| uri.scheme = 'bookmeplus' }.to_s
          expect(base.callback_url).to eq(expected)
          expect(base.callback_url).to start_with('bookmeplus://')
        end
      end

      context 'and platform is web' do
        let(:options) { { platform: 'web' } }

        it 'returns the plain processing url unchanged' do
          expect(base.callback_url).to eq(base.continue_success_url)
        end
      end

      context 'and platform is not supplied' do
        let(:options) { {} }

        it 'returns the plain processing url unchanged' do
          expect(base.callback_url).to eq(base.continue_success_url)
        end
      end
    end
  end
end
