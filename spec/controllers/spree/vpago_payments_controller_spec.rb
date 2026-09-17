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

  describe 'GET #check_transaction' do
    let(:params) do
      {
        order_number: order.number,
        payment_number: payment.number,
        order_jwt_token: checkout.order_jwt_token
      }
    end

    context 'when the gateway times out' do
      before do
        allow_any_instance_of(Spree::Gateway::PaywayV2).to receive(:check_transaction).and_raise(Faraday::TimeoutError)
      end

      it 'returns a pending status instead of an error' do
        get '/vpago_payments/check_transaction', params: params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => 'pending' })
      end
    end

    context 'when the gateway connection fails' do
      before do
        allow_any_instance_of(Spree::Gateway::PaywayV2).to receive(:check_transaction).and_raise(Faraday::ConnectionFailed, 'connection reset')
      end

      it 'returns a pending status instead of an error' do
        get '/vpago_payments/check_transaction', params: params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => 'pending' })
      end
    end
  end

  describe 'POST #create_transaction' do
    let(:params) do
      {
        order_number: order.number,
        payment_number: payment.number,
        order_jwt_token: checkout.order_jwt_token,
        platform: 'app'
      }
    end

    context 'when the gateway supports create_transaction' do
      it 'renders the raw gateway response as JSON' do
        allow_any_instance_of(Spree::Gateway::PaywayV2)
          .to receive(:create_transaction)
          .with(payment, platform: 'app')
          .and_return({ 'status' => { 'code' => 0 }, 'abapay_deeplink' => 'aba://pay' })

        post '/vpago_payments/create_transaction', params: params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => { 'code' => 0 }, 'abapay_deeplink' => 'aba://pay' })
      end
    end

    context 'when the gateway does not support create_transaction' do
      it 'returns a not_implemented status' do
        allow_any_instance_of(Spree::Gateway::PaywayV2).to receive(:support_create_transaction_api?).and_return(false)

        post '/vpago_payments/create_transaction', params: params

        expect(response).to have_http_status(:not_implemented)
        expect(JSON.parse(response.body)).to eq({ 'error' => true, 'message' => 'unsupported' })
      end
    end

    context 'when the gateway call fails' do
      it 'returns a bad_gateway status instead of raising' do
        allow_any_instance_of(Spree::Gateway::PaywayV2).to receive(:create_transaction).and_raise(Faraday::TimeoutError)

        post '/vpago_payments/create_transaction', params: params

        expect(response).to have_http_status(:bad_gateway)
        expect(JSON.parse(response.body)).to eq({ 'error' => true, 'message' => 'Failed to create transaction' })
      end
    end
  end
end
