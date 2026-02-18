require 'spec_helper'

RSpec.describe Spree::VpagoPaymentsController, type: :controller do
  let(:order) { create(:order, number: 'R131576461') }
  let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order) }

  before do
    # Mock the payment finder to avoid JWT token issues
    allow(Vpago::PaymentFinder).to receive(:new).and_return(double(find_and_verify: payment))
    allow(payment).to receive(:checkout?).and_return(true)
  end

  describe 'GET #checkout' do
    context 'with ABA KHQR payment in in-app browser' do
      let(:payment_method) { create(:payway_v2_gateway, preferred_payment_option: 'abapay_khqr') }

      before do
        # Re-create payment with the correct payment method
        payment.update!(payment_method: payment_method)
      end

      context 'Facebook in-app browser' do
        it 'sets @offsite_payment to true' do
          payment_url_constructor = Vpago::PaymentUrlConstructor.new(payment)
          request.headers['User-Agent'] = 'FBAN/4.0 (iPhone; iOS 14.0; Scale/2.00)'
          get :checkout, params: {
            order_number: order.number,
            payment_number: payment.number,
            check_in_app_browser: 'true',
            order_jwt_token: payment_url_constructor.send(:order_jwt_token)
          }

          expect(assigns(:offsite_payment)).to be true
          expect(response).to have_http_status(:ok)
        end
      end

      context 'Telegram in-app browser' do
        it 'sets @offsite_payment to true' do
          payment_url_constructor = Vpago::PaymentUrlConstructor.new(payment)
          request.headers['User-Agent'] = 'Telegram/4.0 (iPhone; iOS 14.0)'
          get :checkout, params: {
            order_number: order.number,
            payment_number: payment.number,
            check_in_app_browser: 'true',
            order_jwt_token: payment_url_constructor.send(:order_jwt_token)
          }

          expect(assigns(:offsite_payment)).to be true
          expect(response).to have_http_status(:ok)
        end
      end

      context 'Facebook Messenger in-app browser' do
        it 'sets @offsite_payment to true' do
          payment_url_constructor = Vpago::PaymentUrlConstructor.new(payment)
          request.headers['User-Agent'] = 'FB_Messenger/4.0 (iPhone; iOS 14.0)'
          get :checkout, params: {
            order_number: order.number,
            payment_number: payment.number,
            check_in_app_browser: 'true',
            order_jwt_token: payment_url_constructor.send(:order_jwt_token)
          }

          expect(assigns(:offsite_payment)).to be true
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'with ABA KHQR payment in regular browser' do
      let(:payment_method) { create(:payway_v2_gateway, preferred_payment_option: 'abapay_khqr') }

      before do
        payment.update!(payment_method: payment_method)
      end

      it 'sets @offsite_payment to false' do
        payment_url_constructor = Vpago::PaymentUrlConstructor.new(payment)
        request.headers['User-Agent'] = 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15'
        get :checkout, params: {
          order_number: order.number,
          payment_number: payment.number,
          check_in_app_browser: 'true',
          order_jwt_token: payment_url_constructor.send(:order_jwt_token)
        }

        expect(assigns(:offsite_payment)).to be false
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with ABA KHQR payment without check_in_app_browser param' do
      let(:payment_method) { create(:payway_v2_gateway, preferred_payment_option: 'abapay_khqr') }

      before do
        payment.update!(payment_method: payment_method)
      end

      it 'sets @offsite_payment to false' do
        payment_url_constructor = Vpago::PaymentUrlConstructor.new(payment)
        request.headers['User-Agent'] = 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15'
        get :checkout, params: {
          order_number: order.number,
          payment_number: payment.number,
          order_jwt_token: payment_url_constructor.send(:order_jwt_token)
        }

        expect(assigns(:offsite_payment)).to be false
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with non-ABA payment method' do
      let(:payment_method) { create(:acleda_mobile_gateway) }

      before do
        payment.update!(payment_method: payment_method)
      end

      it 'sets @offsite_payment to false regardless of browser' do
        payment_url_constructor = Vpago::PaymentUrlConstructor.new(payment)
        request.headers['User-Agent'] = 'FBAN/4.0 (iPhone; iOS 14.0; Scale/2.00)'
        get :checkout, params: {
          order_number: order.number,
          payment_number: payment.number,
          order_jwt_token: payment_url_constructor.send(:order_jwt_token)
        }

        expect(assigns(:offsite_payment)).to be false
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with True Money payment' do
      let(:payment_method) { create(:true_money_gateway) }

      before do
        payment.update!(payment_method: payment_method)
        # Mock the true money checkout to avoid VCR issues
        allow_any_instance_of(Vpago::TrueMoney::Checkout).to receive(:generate_payment_urls).and_return({})
      end

      it 'sets @offsite_payment to true when offsite_payment param is true' do
        payment_url_constructor = Vpago::PaymentUrlConstructor.new(payment)
        request.headers['User-Agent'] = 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15'
        get :checkout, params: {
          order_number: order.number,
          payment_number: payment.number,
          offsite_payment: 'true',
          order_jwt_token: payment_url_constructor.send(:order_jwt_token)
        }

        expect(assigns(:offsite_payment)).to be true
        expect(response).to have_http_status(:ok)
      end

      it 'sets @offsite_payment to false when offsite_payment param is false' do
        payment_url_constructor = Vpago::PaymentUrlConstructor.new(payment)
        request.headers['User-Agent'] = 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15'
        get :checkout, params: {
          order_number: order.number,
          payment_number: payment.number,
          offsite_payment: 'false',
          order_jwt_token: payment_url_constructor.send(:order_jwt_token)
        }

        expect(assigns(:offsite_payment)).to be false
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with ABA KHQR_DEEPLINK payment' do
      let(:payment_method) { create(:payway_v2_gateway, preferred_payment_option: 'abapay_khqr_deeplink') }

      before do
        payment.update!(payment_method: payment_method)
      end

      it 'sets @offsite_payment to true in in-app browser' do
        payment_url_constructor = Vpago::PaymentUrlConstructor.new(payment)
        request.headers['User-Agent'] = 'FBAN/4.0 (iPhone; iOS 14.0; Scale/2.00)'
        get :checkout, params: {
          order_number: order.number,
          payment_number: payment.number,
          check_in_app_browser: 'true',
          order_jwt_token: payment_url_constructor.send(:order_jwt_token)
        }

        expect(assigns(:offsite_payment)).to be true
        expect(response).to have_http_status(:ok)
      end

      it 'sets @offsite_payment to false in regular browser' do
        payment_url_constructor = Vpago::PaymentUrlConstructor.new(payment)
        request.headers['User-Agent'] = 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15'
        get :checkout, params: {
          order_number: order.number,
          payment_number: payment.number,
          check_in_app_browser: 'true',
          order_jwt_token: payment_url_constructor.send(:order_jwt_token)
        }

        expect(assigns(:offsite_payment)).to be false
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with other ABA payment option' do
      let(:payment_method) { create(:payway_v2_gateway, preferred_payment_option: 'abapay_qr') }

      before do
        payment.update!(payment_method: payment_method)
      end

      it 'sets @offsite_payment to false regardless of browser' do
        payment_url_constructor = Vpago::PaymentUrlConstructor.new(payment)
        request.headers['User-Agent'] = 'FBAN/4.0 (iPhone; iOS 14.0; Scale/2.00)'
        get :checkout, params: {
          order_number: order.number,
          payment_number: payment.number,
          order_jwt_token: payment_url_constructor.send(:order_jwt_token)
        }

        expect(assigns(:offsite_payment)).to be false
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST #process_payment' do
    context 'when request from ABA (return)' do
      let(:checkout) { Vpago::PaywayV2::Checkout.new(payment) }
      let(:params) { { tran_id: payment.number, return_params: checkout.return_params } }

      it 'find payment with return params & enqueues the PaymentProcessorJob' do
        expect {
          post :process_payment, params: params
        }.to have_enqueued_job(Vpago::PaymentProcessorJob).with(payment_number: payment.number)
      end
    end
  end
end
