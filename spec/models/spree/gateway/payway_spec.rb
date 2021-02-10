require 'spec_helper'

RSpec.describe Spree::Gateway::Payway, type: :model do
  let(:payment_state) { :payment }
  let(:payway_gateway) { create(:payway_gateway, auto_capture: true) }
  let(:payment_source) { create(:payway_payment_source, payment_method: payway_gateway) }

  let(:order) { OrderWalkthrough.up_to( payment_state) }
  let(:payment) { create(:payway_payment, payment_method: payway_gateway, source: payment_source, order: order) }

  describe '#process' do

    it "transform payment state from checkout to processing" do
      checkout = payment.state

      expect(checkout).to eq('checkout')
      payment.process!
      expect(payment.state).to eq('processing')
    end
  end
end
