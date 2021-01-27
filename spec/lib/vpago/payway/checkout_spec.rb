require 'spec_helper'

RSpec.describe Vpago::Payway::Checkout do
  describe "#hash_hmac" do
    it "return base64encoded value" do
      anything = nil
      checkout = Vpago::Payway::Checkout.new(anything)

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

end
