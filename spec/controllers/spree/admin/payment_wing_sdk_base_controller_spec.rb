require 'spec_helper'

RSpec.describe Spree::Admin::PaymentWingSdkBaseController, type: :controller do
  controller do
    def update
      render plain: :ok
    end
  end
  
  stub_authorization!

  let(:user) { create(:user) }
  let(:gateway) { create(:wing_sdk_gateway, auto_capture: true) }
  let(:payment_source) { create(:wing_sdk_payment_source, payment_method: gateway) }

  let(:order) { create(:order, state: 'payment') }
  let(:payment) { create(:wing_sdk_payment, payment_method: gateway, source: payment_source, order: order) }

  describe "Put update" do
    it "redirect to with error if order if complated" do
      allow_any_instance_of(Spree::Order).to receive(:completed?).and_return(true)
      put :update, params: {id: payment.number}

      expect(flash[:error]).to eq  Spree.t('vpago.payments.not_allow_for_order_completed')
      expect(response.status).to eq 302
      expect(response).to redirect_to( admin_order_payment_path(order_id: order.number, id: payment.number) )
    end

    it "passes the validate order" do
      put :update, params: {id: payment.number}
      expect(response.status).to eq 200
      expect(response.body).to eq "ok"
    end
  end
end
