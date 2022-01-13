require 'spec_helper'

RSpec.describe Spree::Webhook::AcledaMobilesController, type: :controller do

  describe 'POST return' do
    let(:payment) { create(:acleda_mobile_payment) }

    it 'response success with status 200 when successfully update the payment' do
      payloads = {
        TransactionId: payment.number,
        PaymentTokenId: "16de81d4-b5ef-ef59-16de-81d4b5efef59",
        TxnAmount: 30,
        SenderName: "Test User",
        SignedHash: "c5b9be690bde7dc8a0abebb1a45c0850359540a4977aecd4cdf13e15a2edfe79",
      }

      allow_any_instance_of(Vpago::AcledaMobile::PaymentRetriever).to receive(:payment).and_return(payment)
      allow_any_instance_of(Vpago::AcledaMobile::PaymentRetriever).to receive(:data_valid?).and_return(true)
      allow_any_instance_of(Spree::Order).to receive(:paid?).and_return(true)

      post :return, params: payloads

      json_response = JSON.parse(response.body)

      expect(response.status).to eq 200
      expect(json_response['status']['message']).to eq 'Success'
      expect(json_response['data']['TransactionId']).to eq payment.number
    end

    it 'response failed with status 201 when signed hash is invalid' do
      payloads = {
        TransactionId: payment.number,
        PaymentTokenId: "16de81d4-b5ef-ef59-16de-81d4b5efef59",
        TxnAmount: 30,
        SenderName: "Test User",
        SignedHash: "c5b9be690bde7dc8a0abebb1a45c0850359540a4977aecd4cdf13e15a2edfe79",
      }

      allow_any_instance_of(Vpago::AcledaMobile::PaymentRetriever).to receive(:call).and_return(payment)
      allow_any_instance_of(Vpago::AcledaMobile::PaymentRetriever).to receive(:payment).and_return(payment)
      allow_any_instance_of(Vpago::AcledaMobile::PaymentRetriever).to receive(:data_valid?).and_return(false)

      post :return, params: payloads

      json_response = JSON.parse(response.body)

      expect(response.status).to eq 201
      expect(json_response['status']['message']).to eq 'Failed'
    end

    it 'response failed with status 203 when cannot find the payment' do
      payloads = {
        TransactionId: 'Invalid',
        PaymentTokenId: "16de81d4-b5ef-ef59-16de-81d4b5efef59",
        TxnAmount: 30,
        SenderName: "Test User",
        SignedHash: "c5b9be690bde7dc8a0abebb1a45c0850359540a4977aecd4cdf13e15a2edfe79",
      }

      allow_any_instance_of(Vpago::AcledaMobile::PaymentRetriever).to receive(:data_valid?).and_return(true)

      post :return, params: payloads

      json_response = JSON.parse(response.body)
      expect(response.status).to eq 203
      expect(json_response['status']['message']).to eq "Payment not found"
    end
  end
end
