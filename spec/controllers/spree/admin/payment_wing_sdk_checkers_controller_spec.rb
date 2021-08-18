require 'spec_helper'

RSpec.describe Spree::Admin::PaymentWingSdkCheckersController, type: :controller do
  stub_authorization!

  let(:user) { create(:user) }

  before do
    allow(controller).to receive_messages spree_current_user: user
  end


  describe "PUT update" do
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
      checker = double(:wing_sdk_status_checker, 'success?': true)
      allow_any_instance_of(Vpago::WingSdk::PaymentRequestUpdater).to receive(:check_wing_status).and_return(checker)

      put :update, params: {id: payment.number}

      payment.reload
      order.reload


      expect(flash[:success]).to eq Spree.t(:successfully_updated, resource: Spree.t(:payments))
      expect(payment.completed?).to eq true
      expect(order.completed?).to eq true

      expect(response.status).to eq 302
      expect(response).to redirect_to( admin_order_payment_path(order_id: order.number, id: payment.number)  )
    end

    it "redirects to order path if payment status updater is false" do
      checker = double(:wing_sdk_status_checker, 'success?': false, error_message: 'error-message')
      allow_any_instance_of(Vpago::WingSdk::PaymentRequestUpdater).to receive(:check_wing_status).and_return(checker)

      put :update, params: {id: payment.number}

      payment.reload
      order.reload
      
      expect(flash[:error]).to eq Spree.t(:unsuccessfully_updated, resource: Spree.t(:payments))
      expect(response.status).to eq 302
      expect(response).to redirect_to( admin_order_payment_path(order_id: order.number, id: payment.number)  )
    end
  end
end
