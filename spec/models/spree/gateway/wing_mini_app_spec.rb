require 'spec_helper'

RSpec.describe Spree::Gateway::WingMiniApp do
  subject(:gateway) { create(:wing_mini_app_gateway) }

  it 'reports the wing_mini_app method type' do
    expect(gateway.method_type).to eq('wing_mini_app')
  end

  it 'auto captures' do
    expect(gateway.auto_capture?).to be true
  end

  it 'uses the vpago payment source' do
    expect(gateway.payment_source_class).to eq(Spree::VpagoPaymentSource)
  end

  it 'is registered as a vpago payment' do
    expect(gateway.vpago_payment?).to be true
    expect(gateway.type_wing_mini_app?).to be true
  end

  it 'does not support check_transaction (no synchronous status API is documented)' do
    expect(gateway.support_check_transaction_api?).to be false
  end

  describe '#purchase' do
    let(:payment) { create(:wing_mini_app_payment, number: 'P123456') }

    def purchase(transaction_response)
      payment.update_column(:transaction_response, transaction_response) # rubocop:disable Rails/SkipsModelValidations
      gateway.purchase(nil, nil, order_id: "R000-#{payment.number}")
    end

    # The secretKey check and the doc-mandated amount/currency match both happen
    # once, at webhook intake, in Vpago::PaymentFinder — see its spec for that
    # coverage (including the debitAmount-without-decimals regression). A present
    # transaction_response here is exactly that verification having already
    # passed, so #purchase has nothing left to re-check.
    it 'succeeds when a verified transaction_response is present' do
      response = purchase('debitAmount' => format('%.2f', payment.amount), 'debitCcy' => payment.currency)

      expect(response.success?).to be true
    end

    it 'fails when there is no transaction_response yet' do
      response = purchase({})

      expect(response.success?).to be false
    end
  end

  describe '#cancel' do
    it 'fails — no refund API is documented for Wing Mini App yet' do
      response = gateway.cancel(nil, nil)

      expect(response.success?).to be false
    end
  end

  describe '#app_id and #secret_api_key' do
    before { stub_wing_mini_app_credentials(app_id: 'from-env', secret_api_key: 'from-env-secret') }

    it 'read the env partner credentials' do
      gateway = build_stubbed(:wing_mini_app_gateway)

      expect(gateway.app_id).to eq('from-env')
      expect(gateway.secret_api_key).to eq('from-env-secret')
    end

    # The login half (SpreeCmCommissioner::WingMiniApp::ProfileVerifier) is env-only, so a
    # per-record override would have signed payments as a different partner than login.
    it 'expose no preference that could override them' do
      gateway = build_stubbed(:wing_mini_app_gateway)

      expect(gateway.has_preference?(:app_id)).to be false
      expect(gateway.has_preference?(:secret_api_key)).to be false
    end
  end
end
