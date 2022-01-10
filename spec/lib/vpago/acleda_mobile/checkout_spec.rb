require 'spec_helper'

RSpec.describe Vpago::AcledaMobile::Checkout do
  it "returns hmac hash" do
    checkout = Vpago::AcledaMobile::Checkout.new(nil, nil)

    key = '933c9fc0ec5946d9a9037d2b2ed59454'
    message = '{"app_name":"VTENH","payment_amount":"31.00","payment_amount_ccy":"USD","payment_purpose":"VTENH Transaction","txn_ref":"PWYFQ93V"}'
    allow(checkout).to receive(:encryption_key).and_return(key)

    hmac_hash = checkout.hmac_hash(key, message)
    p hmac_hash
    # a278b40144c75fd2597a08c861d795c174bd7f675385864c3b1c3436e308d818
    expect(hmac_hash).to eq 'a278b40144c75fd2597a08c861d795c174bd7f675385864c3b1c3436e308d818'
  end

end
