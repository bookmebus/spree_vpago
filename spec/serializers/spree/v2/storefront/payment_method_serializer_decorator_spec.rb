require 'spec_helper'

RSpec.describe Spree::V2::Storefront::PaymentMethodSerializer do
  let(:payment_method) { create(:cash_on_payment_method) }
  let(:serialized_type) { described_class.new(payment_method).serializable_hash[:data][:attributes][:type] }

  around do |example|
    original = ENV['PAYMENT_METHOD_VIEW']
    example.run
    ENV['PAYMENT_METHOD_VIEW'] = original
  end

  context 'when PAYMENT_METHOD_VIEW is not set' do
    before { ENV.delete('PAYMENT_METHOD_VIEW') }

    it 'defaults to joining all payment methods into one type' do
      expect(serialized_type).to eq('payment_method')
    end
  end

  context 'when PAYMENT_METHOD_VIEW is "join"' do
    before { ENV['PAYMENT_METHOD_VIEW'] = 'join' }

    it 'groups all payment methods under one type' do
      expect(serialized_type).to eq('payment_method')
    end
  end

  context 'when PAYMENT_METHOD_VIEW is "split"' do
    before { ENV['PAYMENT_METHOD_VIEW'] = 'split' }

    it 'returns the payment method own type' do
      expect(serialized_type).to eq(payment_method.type)
    end
  end
end
