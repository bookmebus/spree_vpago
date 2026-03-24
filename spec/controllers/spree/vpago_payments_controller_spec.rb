require 'spec_helper'

RSpec.describe Spree::VpagoPaymentsController, type: :request do
  let(:order) { create(:order, number: 'R131576461') }
  let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order) }
  let(:checkout) { Vpago::PaywayV2::Checkout.new(payment) }

  describe 'POST #process_payment' do
    context 'when request from ABA (return)' do
      let(:params) { { tran_id: payment.number, return_params: checkout.return_params } }

      it 'find payment with return params & enqueues the PaymentProcessorJob' do
        expect {
          post '/vpago_payments/process_payment', params: params
        }.to have_enqueued_job(Vpago::PaymentProcessorJob).with(payment_number: payment.number)
      end
    end

    context 'when in reviewing mode with payway_v2' do
      let(:params) { { tran_id: payment.number, return_params: checkout.return_params } }

      context 'and request is from external server (bank)' do
        before do
          payment.payment_method.update!(preferred_reviewing_mode: true)
        end

        it 'does not enqueue PaymentProcessorJob' do
          expect {
            post '/vpago_payments/process_payment', params: params
          }.not_to have_enqueued_job(Vpago::PaymentProcessorJob)
        end

        it 'returns status ok' do
          post '/vpago_payments/process_payment', params: params

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to eq({ 'status' => 'ok' })
        end
      end

      context 'and request is from internal client' do
        let(:params_with_internal_client) { { tran_id: payment.number, return_params: checkout.return_params, internal_client: 'true' } }

        before do
          payment.payment_method.update!(preferred_reviewing_mode: true)
        end

        it 'enqueues PaymentProcessorJob' do
          expect {
            post '/vpago_payments/process_payment', params: params_with_internal_client
          }.to have_enqueued_job(Vpago::PaymentProcessorJob).with(payment_number: payment.number)
        end
      end
    end
  end
end
