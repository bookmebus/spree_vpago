require 'spec_helper'

RSpec.describe Spree::VpagoPaymentsController, type: :request do
  let(:order) { create(:order, number: 'R131576461') }
  let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order) }
  let(:checkout) { Vpago::PaywayV2::Checkout.new(payment) }

  describe 'GET #checkout' do
    context 'when the payment method is store credit' do
      let(:wallet_user) { create(:user) }
      let(:wallet_order) { create(:order, user: wallet_user, number: 'R131576462', total: 25.00, currency: 'USD') }
      let(:store_credit_method) { create(:store_credit_payment_method, stores: [wallet_order.store]) }
      let(:credit) { create(:store_credit, user: wallet_user, amount: 30.00, store: wallet_order.store) }
      let(:store_credit_payment) do
        create(:store_credit_payment, order: wallet_order, source: credit, payment_method: store_credit_method,
                                       amount: 25.00, number: 'PSTORECREDIT1')
      end
      let(:jwt_token) { JWT.encode({ order_number: wallet_order.number, order_id: wallet_order.id }, wallet_order.token, 'HS256') }

      it 'redirects to the processing page instead of raising a missing-partial error' do
        get '/vpago_payments/checkout', params: {
          payment_number: store_credit_payment.number,
          order_number: wallet_order.number,
          order_jwt_token: jwt_token
        }

        expect(response).to redirect_to(store_credit_payment.processing_url)
      end
    end

    context 'when the payment method is CashOn (non-gateway, no form partial either)' do
      let(:cash_user) { create(:user) }
      let(:cash_order) { create(:order, user: cash_user, number: 'R131576463', total: 15.00, currency: 'USD') }
      let(:cash_on_method) { Spree::PaymentMethod::CashOn.create!(name: 'Cash on Delivery', stores: [cash_order.store]) }
      let(:cash_on_payment) do
        # CashOn#source_required? is true, so Payment validates source presence -- the source's
        # actual type is irrelevant to what's under test here (payment_method-based partial
        # lookup), so a plain credit card record just satisfies that validation.
        create(:payment, order: cash_order, source: create(:credit_card), payment_method: cash_on_method,
                          amount: 15.00, number: 'PCASHON1')
      end
      let(:jwt_token) { JWT.encode({ order_number: cash_order.number, order_id: cash_order.id }, cash_order.token, 'HS256') }

      it 'redirects to the processing page instead of raising a missing-partial error' do
        get '/vpago_payments/checkout', params: {
          payment_number: cash_on_payment.number,
          order_number: cash_order.number,
          order_jwt_token: jwt_token
        }

        expect(response).to redirect_to(cash_on_payment.processing_url)
      end
    end
  end

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
end
