require 'spec_helper'

RSpec.describe Spree::VpagoOrdersController, type: :request do
  let(:order) { create(:order, number: 'R131576461') }
  let(:jwt_token) { Vpago::OrderUrlConstructor.new(order).send(:order_jwt_token) }
  let(:params) { { order_number: order.number, order_jwt_token: jwt_token } }

  describe 'GET #processing' do
    context 'when the order is already completed' do
      let(:order) { create(:completed_order_with_totals, number: 'R131576461') }

      it 'redirects to the success page' do
        get '/vpago_orders/processing', params: params

        expect(response).to redirect_to(order.success_url)
      end
    end

    context 'when the jwt token or order number is invalid' do
      it 'renders not found' do
        get '/vpago_orders/processing', params: params.merge(order_jwt_token: 'invalid-jwt')

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET #success' do
    context 'when the order is not completed' do
      it 'raises access denied' do
        get '/vpago_orders/success', params: params

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #process_order' do
    context 'when the order is found and not yet completed' do
      it 'enqueues the OrderProcessorJob' do
        expect {
          post '/vpago_orders/process_order', params: params
        }.to have_enqueued_job(Vpago::OrderProcessorJob).with(order_number: order.number)
      end

      it 'returns status ok' do
        post '/vpago_orders/process_order', params: params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'status' => 'ok' })
      end
    end

    context 'when the order is already completed' do
      let(:order) { create(:completed_order_with_totals, number: 'R131576461') }

      it 'does not enqueue the OrderProcessorJob' do
        expect {
          post '/vpago_orders/process_order', params: params
        }.not_to have_enqueued_job(Vpago::OrderProcessorJob)
      end
    end

    context 'when the order is not found' do
      it 'renders not found' do
        post '/vpago_orders/process_order', params: params.merge(order_number: 'INVALID')

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
