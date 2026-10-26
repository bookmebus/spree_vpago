require 'spec_helper'

RSpec.describe Vpago::Vattanac::TransactionStatus do
  let(:order) { create(:order, number: 'R131576461') }
  let(:payment) { create(:vattanac_payment, number: 'PJ0MYD2Y', order: order) }

  subject(:transaction_status) { described_class.new(payment) }

  before { allow(subject).to receive(:access_token).and_return('abc123') }

  describe '#call' do
    it 'posts the transaction id and stores the parsed response' do
      response = double('Response', body: { data: { status: 'SUCCESS' } }.to_json)
      connection = instance_double(Faraday::Connection, post: response)
      allow(Faraday).to receive(:new).and_return(connection)

      transaction_status.call

      expect(transaction_status.success?).to be true
      expect(transaction_status.json_response).to eq({ 'data' => { 'status' => 'SUCCESS' } })
    end

    it 'propagates a Faraday timeout instead of swallowing it' do
      allow(Faraday).to receive(:new).and_raise(Faraday::TimeoutError)

      expect { transaction_status.call }.to raise_error(Faraday::TimeoutError)
    end
  end
end
