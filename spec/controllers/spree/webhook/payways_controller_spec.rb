require 'spec_helper'

RSpec.describe Spree::Webhook::PaywaysController, type: :controller do
  render_views

  describe "GET return" do
    it "return ok" do
      get :return

      expect(response.status).to eq 200
      expect(response.body).to eq "ok"
    end
  end

  describe "POST return" do
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
      payload = { tran_id: payment.number, status: 0}.to_json
      payment_success = double(:payment_status_updater, 'success?': true)
      allow_any_instance_of(Vpago::Payway::PaymentStatusUpdater).to receive(:check_payway_status).and_return(payment_success)

      post :return, params: {response: payload}
      # expect(subject).to redirect_to order_path(order.reload)
      expect(response.body).to eq 'success'
    end

    it "redirects to checkout with state :payment path if payment status updater is failed" do
      payload = { tran_id: payment.number, status: 0}.to_json
      payment_failed = double(:payment_status_updater, 'success?': false, error_message: "Invalid transaction from Payway")
      allow_any_instance_of(Vpago::Payway::PaymentStatusUpdater).to receive(:check_payway_status).and_return(payment_failed)

      post :return, params: {response: payload}
      expect(response.status).to eq 400
    end
  end

  describe "GET continue" do
    let(:order) { OrderWalkthrough.up_to( :payment) }
    let(:payment) { create(:payway_payment, order: order) }

    it "redirects to order path if payment status updater is success" do
      payment.complete!
      payment.order.finalize!
      payment.order.update(state: 'complete', completed_at: Time.zone.now)

      get :continue, params: {tran_id: payment.number}
      expect(subject).to redirect_to order_path(order.reload)
    end

    it "redirects to checkout with state :payment path if payment status updater is failed" do
      get :continue, params: {tran_id: payment.number}
      expect(subject).to redirect_to checkout_state_path(:payment)
    end
  end



end