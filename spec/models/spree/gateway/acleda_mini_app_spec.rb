require 'spec_helper'

RSpec.describe Spree::Gateway::AcledaMiniApp do
  subject(:gateway) { create(:acleda_mini_app_gateway) }

  it 'is an AcledaV2 gateway variant' do
    expect(gateway).to be_a(Spree::Gateway::AcledaV2)
  end

  it 'reports the acleda_mini_app method type' do
    expect(gateway.method_type).to eq('acleda_mini_app')
  end

  it 'always runs in deeplink mode' do
    expect(gateway.deeplink?).to be true
  end

  it 'auto captures' do
    expect(gateway.auto_capture?).to be true
  end

  it 'uses the vpago payment source' do
    expect(gateway.payment_source_class).to eq(Spree::VpagoPaymentSource)
  end

  it 'is registered as a vpago payment' do
    expect(gateway.vpago_payment?).to be true
    expect(gateway.type_acleda_mini_app?).to be true
  end

  it 'inherits AcledaV2 check_transaction support' do
    expect(gateway).to respond_to(:check_transaction)
    expect(gateway.support_check_transaction_api?).to be true
  end
end
