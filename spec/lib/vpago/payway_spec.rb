require 'spec_helper'

RSpec.describe Vpago::Payway do
  it "defines Vpago::Payway::TYPE_ABA_PAY" do
    expect(Vpago::Payway::CARD_TYPE_ABAPAY).to eq 'abapay'
  end

  it "defines Vpago::Payway::TYPE_ABA_PAY" do
    expect(Vpago::Payway::CARD_TYPE_CARDS).to eq 'cards'
  end

  it "defines Vpago::Payway::TYPES" do
    expect(Vpago::Payway::CARD_TYPES).to eq ['abapay', 'abapay_khqr', 'cards', 'wechat', 'alipay']
  end

end