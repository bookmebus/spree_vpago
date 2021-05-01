require 'spec_helper'

RSpec.describe Spree::Admin::PaymentPaywayQueriersController, type: :controller do
  stub_authorization!

  let(:user) { create(:user) }

  before do
    allow(controller).to receive_messages spree_current_user: user
  end


  describe "GET show" do
    let(:gateway) { create(:payway_gateway, auto_capture: true) }
    let(:payment_source) { create(:payway_payment_source, payment_method: gateway) }
  
    let(:order) { OrderWalkthrough.up_to( :payment) }
    let(:payment) { create(:payway_payment, payment_method: gateway, source: payment_source, order: order) }

    before(:each) do
      gateway.set_preference(:api_key, "api_key")
      gateway.set_preference(:merchant_id, "vtenh")
      gateway.set_preference(:endpoint, "https://payway-staging.ababank.com/api/pwvtenhv/")
      gateway.set_preference(:return_url, "https://vtenh.com/webkook/payway_return_url")
      gateway.set_preference(:continue_success_url, "https://vtenh.com/webkook/payway_continue_url")
      gateway.set_preference(:payment_option, "cards")
      gateway.set_preference(:transaction_fee_fix, 0)
      gateway.save

      payment.process!
    end

    it "redirects to order path if payment status updater is success" do

      tran_status_result = double(:tran_status_result, success?: true, result: {"status"=>0} )
      expect(Vpago::Payway::TransactionStatus).to receive(:new).with(payment).and_return(tran_status_result)
      expect(tran_status_result).to receive(:call)

      get :show, params: {id: payment.number}

      expect(flash[:success]).to eq Spree.t('vpago.payments.payment_found_with_result', result: tran_status_result.result)
      expect(response.status).to eq 302
      expect(response).to redirect_to( admin_order_payment_path(order_id: order.number, id: payment.number))
    end

    it "redirects to order path if payment status updater is false" do
      tran_status_result = double(:tran_status_result, success?: false, error_message:  {"status"=>1} )
      expect(Vpago::Payway::TransactionStatus).to receive(:new).with(payment).and_return(tran_status_result)
      expect(tran_status_result).to receive(:call)

      get :show, params: {id: payment.number}

      expect(flash[:error]).to eq Spree.t('vpago.payments.payment_not_found_with_error', error: tran_status_result.error_message)
      expect(response.status).to eq 302
      expect(response).to redirect_to( admin_order_payment_path(order_id: order.number, id: payment.number))
    end

  end



end