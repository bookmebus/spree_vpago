require 'spec_helper'

RSpec.describe Vpago::AcledaMobile::CallbackValidator do
  it 'check callback data' do
    payloads = {
      TransactionId: "REF0361472663",
      PaymentTokenId: "16de81d4-b5ef-ef59-16de-81d4b5efef59",
      TxnAmount: 30,
      SenderName: "Test User",
      SignedHash: "c5b9be690bde7dc8a0abebb1a45c0850359540a4977aecd4cdf13e15a2edfe79",
    }

    key = 'VTenhSecret'

    service = Vpago::AcledaMobile::CallbackValidator.new(payloads)
    allow(service).to receive(:secret_key).and_return(key)

    expect(service.call).to eq true
  end

  it 'return hmac' do
    payloads = {
      TransactionId: "REF0361472663",
      PaymentTokenId: "16de81d4-b5ef-ef59-16de-81d4b5efef59",
      TxnAmount: 30,
      SenderName: "Test User",
      SignedHash: "c5b9be690bde7dc8a0abebb1a45c0850359540a4977aecd4cdf13e15a2edfe79",
    }

    key = 'VTenhSecret'

    service = Vpago::AcledaMobile::CallbackValidator.new(payloads)
    allow(service).to receive(:secret_key).and_return(key)

     
     expect(service.hmac_hash).to eq 'c5b9be690bde7dc8a0abebb1a45c0850359540a4977aecd4cdf13e15a2edfe79'
  end
end
