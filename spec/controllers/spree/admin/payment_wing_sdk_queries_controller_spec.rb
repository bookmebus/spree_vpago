require 'spec_helper'

RSpec.describe Spree::Admin::PaymentWingSdkQueriersController, type: :controller do
  stub_authorization!

  let(:user) { create(:user) }

  before do
    allow(controller).to receive_messages spree_current_user: user
  end

  describe "GET show" do
    let(:gateway) { create(:wing_sdk_gateway, auto_capture: true) }
    let(:payment_source) { create(:wing_sdk_payment_source, payment_method: gateway) }
  
    let(:order) { create(:order, state: 'payment') }
    let(:payment) { create(:wing_sdk_payment, payment_method: gateway, source: payment_source, order: order) }

    before(:each) do
      gateway.set_preference(:rest_api_key, "api_key")
      gateway.set_preference(:username, "vtenh")
      gateway.set_preference(:biller_code, "2001")
      gateway.set_preference(:sandbox, true)
      gateway.set_preference(:return_url, 'https://vtenh.com/webhook/wings/return')
      gateway.set_preference(:host, 'https://stageonline.wingmoney.com')
      gateway.set_preference(:transaction_fee_fix, 0)
      gateway.save

      payment.process!
    end

    it "redirects to order path if payment status updater is success" do

      tran_status_result = double(:tran_status_result, success?: true, result: {"errorCode"=>200} )
      expect(Vpago::WingSdk::TransactionStatusChecker).to receive(:new).with(payment).and_return(tran_status_result)
      expect(tran_status_result).to receive(:call)

      get :show, params: {id: payment.number}

      expect(flash[:success]).to eq Spree.t('vpago.payments.payment_found_with_result', result: tran_status_result.result)
      expect(response.status).to eq 302
      expect(response).to redirect_to( admin_order_payment_path(order_id: order.number, id: payment.number))
    end

    it "redirects to order path if payment status updater is false" do
      tran_status_result = double(:tran_status_result, success?: false, error_message:  {"errorCode"=>100} )
      expect(Vpago::WingSdk::TransactionStatusChecker).to receive(:new).with(payment).and_return(tran_status_result)
      expect(tran_status_result).to receive(:call)

      get :show, params: {id: payment.number}

      expect(flash[:error]).to eq Spree.t('vpago.payments.payment_not_found_with_error', error: tran_status_result.error_message)
      expect(response.status).to eq 302
      expect(response).to redirect_to( admin_order_payment_path(order_id: order.number, id: payment.number))
    end
  end
end
