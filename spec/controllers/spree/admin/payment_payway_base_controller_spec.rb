require 'spec_helper'

RSpec.describe Spree::Admin::PaymentPaywayBaseController, type: :controller do
  
  controller do
    def update
      render plain: :ok
    end
  end
  
  stub_authorization!

  let(:user) { create(:user) }
  let(:gateway) { create(:payway_gateway, auto_capture: true) }
  let(:payment_source) { create(:payway_payment_source, payment_method: gateway) }

  let(:order) { OrderWalkthrough.up_to( :payment) }
  let(:payment) { create(:payway_payment, payment_method: gateway, source: payment_source, order: order) }

  describe "Put update" do
    it "passes the validate order" do
      put :update, params: {id: payment.number}
      expect(response.status).to eq 200
      expect(response.body).to eq "ok"
    end
  end
end
