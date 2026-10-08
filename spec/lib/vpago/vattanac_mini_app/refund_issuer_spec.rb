require 'spec_helper'

RSpec.describe Vpago::VattanacMiniApp::RefundIssuer, :vcr do
  let(:order) { create(:order, number: 'R131576461') }

  let(:payment) do
    create(:vattanac_mini_app_payment, number: 'PJ0MYD2Y', order: order, transaction_response: {
      "amount" => 1.0,
      "status" => "SUCCESS",
      "currency" => "USD",
      "expiredIn" => 1_748_922_824_154,
      "paymentId" => "PQ48I7FK",
      "transactionId" => "IMPMT030000096458",
      "additionalData" => nil
    })
  end

  subject { described_class.new(payment) }

  before do
    allow(subject).to receive(:refund_url).and_return('https://dev-pay.vattanacbank.com/api/miniapp/refund')
    allow(subject).to receive(:partner_code).and_return('mocked_partner_code')
    allow_any_instance_of(Vpago::VattanacMiniAppDataHandler).to receive(:encrypted_data).and_return('mocked_encrypted_data')
    allow_any_instance_of(Vpago::VattanacMiniAppDataHandler).to receive(:decrypt_data).and_return({ 
      "status" => "SUCCESS",
      "transactionId" => "IMPMT030000096458",
      "paymentId" => "PQ48I7FK",
      "amount" => 1.0,
      "currency" => "USD"
     })
  end

  describe '#call', vcr: { cassette_name: 'vpago/refund_issuer/refund_success_request' } do
    it 'successfully processes a refund request' do
      result = subject.call

      expect(subject.success?).to be true
      expect(result['status']).to eq('SUCCESS')
    end
  end
end

