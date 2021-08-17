require 'spec_helper'

RSpec.describe Spree::Admin::PaymentWingSdkMarkersController, type: :controller do
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

    it 'requires update_reason' do
      put :update, params: {id: payment.number, update_reason: ' ' }
      
      payment.reload
      order.reload

      expect(flash[:error]).to eq Spree.t('vpago.payments.failed_require_updated_reason')
      expect(payment.completed?).to eq false
      expect(order.completed?).to eq false

      expect(response.status).to eq 302
      expect(response).to redirect_to( admin_order_payment_path(order_id: order.number, id: payment.number) )
    end

    it "redirects to order path if payment status updater is success" do
      reason = 'my-reason'
      put :update, params: {id: payment.number, updated_reason: reason }

      payment.reload
      order.reload

      expect(flash[:success]).to eq Spree.t(:successfully_updated, resource: Spree.t(:payments))
      expect(payment.completed?).to eq true
      expect(order.completed?).to eq true

      expect(response.status).to eq 302
      expect(response).to redirect_to( admin_order_payment_path(order_id: order.number, id: payment.number) )
    end
  end
end
