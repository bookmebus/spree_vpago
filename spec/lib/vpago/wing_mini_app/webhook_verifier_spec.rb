require 'spec_helper'

RSpec.describe Vpago::WingMiniApp::WebhookVerifier do
  let(:payment) do
    create(:wing_mini_app_payment, number: 'R000-P123456', amount: 19.9, order: create(:order, currency: 'USD'))
  end

  let(:app_id) { 'WG_APPID_0001' }
  let(:secret_api_key) { 'super-secret-key' }

  before { stub_wing_mini_app_credentials(app_id: app_id, secret_api_key: secret_api_key) }

  def signed_payload(fields, secret: secret_api_key)
    plaintext = "#{app_id}#{described_class::FIELDS.map { |f| fields[f].to_s }.join}#{secret}"
    hash = Digest::SHA256.hexdigest(plaintext.upcase).upcase

    fields.merge('secretKey' => hash)
  end

  let(:valid_fields) do
    {
      'orderRef' => payment.number,
      'debitAmount' => '19.90',
      'debitCcy' => 'USD',
      'transactionId' => '0002352252200038',
      'transactionDate' => '2023-08-29 13:45:53'
    }
  end

  it 'accepts a payload whose secretKey matches this payment and whose amount/currency match too' do
    payload = signed_payload(valid_fields)

    expect(described_class.new(payload, payment).valid?).to be true
  end

  it 'rejects a payload with no secretKey' do
    payload = valid_fields

    expect(described_class.new(payload, payment).valid?).to be false
  end

  it 'rejects a payload whose secretKey was computed for a different amount' do
    payload = signed_payload(valid_fields)
    payload['debitAmount'] = '1.00'

    expect(described_class.new(payload, payment).valid?).to be false
  end

  # Regression hypothesis: Wing may compute secretKey against the canonical
  # 2-decimal debitAmount ("1.00") but transmit a differently-formatted field
  # ("1") — this must still verify, without weakening detection of a genuinely
  # wrong amount (covered above).
  it 'accepts a payload whose secretKey was computed with 2 decimals but debitAmount arrives without them' do
    payload = signed_payload(valid_fields.merge('debitAmount' => '19.90'))
    payload['debitAmount'] = '19.9'

    expect(described_class.new(payload, payment).valid?).to be true
  end

  it 'rejects a payload signed with a different secret_api_key' do
    payload = signed_payload(valid_fields, secret: 'wrong-secret')

    expect(described_class.new(payload, payment).valid?).to be false
  end

  # Doc-mandated ("the Miniapp Web Partner must verify that the transaction
  # amount from Wing Bank matches the amount recorded in the Miniapp database")
  # — a validly-signed webhook for the wrong amount must still be rejected, since
  # Wing holds the keys and could sign any amount for a real orderRef.
  it 'rejects a validly-signed payload whose amount does not match the payment' do
    mismatched_payment = create(:wing_mini_app_payment, number: 'R000-WRONGAMT', amount: 999.0, order: create(:order, currency: 'USD'))
    payload = signed_payload(valid_fields)

    expect(described_class.new(payload, mismatched_payment).valid?).to be false
  end

  it 'rejects a validly-signed payload whose currency does not match the payment' do
    mismatched_payment = create(:wing_mini_app_payment, number: 'R000-WRONGCCY', amount: 19.9, order: create(:order, currency: 'KHR'))
    payload = signed_payload(valid_fields)

    expect(described_class.new(payload, mismatched_payment).valid?).to be false
  end
end
