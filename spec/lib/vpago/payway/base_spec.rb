require 'spec_helper'

RSpec.describe Vpago::Payway::Base do
  describe "#hash_hmac" do
    it "return base64encoded value" do
      anything = nil
      checkout = Vpago::Payway::Base.new(anything)

      allow(checkout).to receive(:amount).and_return "10.00"
      allow(checkout).to receive(:transaction_id).and_return "12124257"
      allow(checkout).to receive(:merchant_id).and_return "bookmebus"
      allow(checkout).to receive(:api_key).and_return "7866ceb0b796eda95e1cc597e9f62e5e"

      result = checkout.hash_hmac
      
      # translat from original php script: spec/services/vpago/payway/checkout_spec.php
      expected = "JthQ6rfzAvHg27TP9HuQ9qxLSkh7Q82yz0OHgIt0+C5yLJ4qpTeol7s1Tthojk0F6mapYrpuGyGs5vZ5mcjhpw=="
      expect(result).to eq expected

    end
  end

  describe '#continue_success_url' do

    let(:payway_gateway) { create(:payway_gateway, auto_capture: true) }

    it "add tran_id if query string does not exist" do

      payway_gateway.set_preference(:continue_success_url, "https://vtenh.com/webkook/payway_continue_url")
      payment = create(:payway_payment, payment_method: payway_gateway)

      checkout = Vpago::Payway::Base.new(payment)
      allow(checkout).to receive(:app_checkout).and_return("no")
      expect(checkout.continue_success_url).to eq "https://vtenh.com/webkook/payway_continue_url?tran_id=#{checkout.transaction_id}&app_checkout=no"

    end

    it "add tran_id if query string does not exist" do

      payway_gateway.set_preference(:continue_success_url, "https://vtenh.com/webkook/payway_continue_url?k=v")
      payment = create(:payway_payment, payment_method: payway_gateway)

      checkout = Vpago::Payway::Base.new(payment)
      allow(checkout).to receive(:app_checkout).and_return("yes")
      
      expect(checkout.continue_success_url).to eq "https://vtenh.com/webkook/payway_continue_url?k=v&tran_id=#{checkout.transaction_id}&app_checkout=yes"

    end

  end


end
