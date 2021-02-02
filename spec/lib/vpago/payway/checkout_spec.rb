require 'spec_helper'

RSpec.describe Vpago::Payway::Checkout do
  describe "#gateway_params" do
    let(:payway_gateway) { create(:payway_gateway, auto_capture: true) }
    let(:payment_source) { create(:payway_payment_source, payment_method: payway_gateway) }

    let(:order) { OrderWalkthrough.up_to(:payment) }

    it "return hash of params for the gateway" do
      payway_gateway.set_preference(:api_key, "api_key")
      payway_gateway.set_preference(:merchant_id, "vtenh")
      payway_gateway.set_preference(:return_url, "https://vtenh.com/webkook/payway_return_url")
      payway_gateway.set_preference(:continue_success_url, "https://vtenh.com/webkook/payway_continue_url")
      payway_gateway.set_preference(:payment_option, "cards")
      payway_gateway.set_preference(:transaction_fee_fix, 0)

      payment = create(:payway_payment, payment_method: payway_gateway, source: payment_source, order: order)

      checkout = Vpago::Payway::Checkout.new(payment)
      result = checkout.gateway_params

      expected = {
        :tran_id=> payment.number,
        :amount=> "#{payment.amount}",
        :hash=> checkout.hash_hmac,
        :firstname=> order.billing_address.first_name,
        :lastname=> order.billing_address.last_name,
        :email=>order.email,
        :payment_option=>"cards",
        :return_url=>"aHR0cHM6Ly92dGVuaC5jb20vd2Via29vay9wYXl3YXlfcmV0dXJuX3VybA==\n",
        :continue_success_url=>checkout.continue_success_url,
        :phone_country_code=> "+855",
        :phone=>order.billing_address.phone,
        :return_params => checkout.return_params
      }

      expect(result).to match expected
    end
  end
end
