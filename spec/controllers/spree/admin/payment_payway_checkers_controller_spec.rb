require 'spec_helper'

RSpec.describe Spree::Admin::PaymentPaywayCheckersController, type: :controller do
  stub_authorization!

  let(:user) { create(:user) }

  before do
    allow(controller).to receive_messages spree_current_user: user
  end


  describe "PUT update" do
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
      checker = double(:payway_status_checker, 'success?': true, result: {status: 0})
      allow_any_instance_of(Vpago::PaywayV2::PaymentRequestUpdater).to receive(:check_payway_status).and_return(checker)

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
      checker = double(:payway_status_checker, 'success?': false, error_message: 'error-message')
      allow_any_instance_of(Vpago::PaywayV2::PaymentRequestUpdater).to receive(:check_payway_status).and_return(checker)

      put :update, params: {id: payment.number}

      payment.reload
      order.reload
      
      expect(flash[:error]).to eq Spree.t(:unsuccessfully_updated, resource: Spree.t(:payments))
      expect(response.status).to eq 302
      expect(response).to redirect_to( admin_order_payment_path(order_id: order.number, id: payment.number)  )
    end

  end



end
