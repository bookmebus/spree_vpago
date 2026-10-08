require 'spec_helper'

RSpec.describe Vpago::OrderUrlConstructor do
  # Generated at run time (not a static literal) so this fixture value never looks like a
  # committed high-entropy secret to scanners like GitGuardian -- it's just Spree::Order's public
  # guest-checkout token, not a credential.
  let(:order) { create(:order, number: 'R322092410', token: SecureRandom.urlsafe_base64(24)) }

  subject { described_class.new(order) }

  describe '#processing_url' do
    it { expect(subject.processing_url).to eq "http://localhost:4000/vpago_orders/processing?order_jwt_token=#{subject.send(:order_jwt_token)}&order_number=R322092410" }
  end

  describe '#success_url' do
    it { expect(subject.success_url).to eq "http://localhost:4000/vpago_orders/success?order_jwt_token=#{subject.send(:order_jwt_token)}&order_number=R322092410" }
  end

  describe '#process_order_url' do
    it { expect(subject.process_order_url).to eq "http://localhost:4000/vpago_orders/process_order?order_jwt_token=#{subject.send(:order_jwt_token)}&order_number=R322092410" }
  end

  describe '#query' do
    it { expect(subject.query).to eq "order_jwt_token=#{subject.send(:order_jwt_token)}&order_number=R322092410" }
  end

  describe '#order_jwt_token' do
    it 'returns encoded JWT of order number with token' do
      payload = { order_number: order.number, order_id: order.id }
      expect(subject.send(:order_jwt_token)).to eq JWT.encode(payload, order.token, 'HS256')
    end
  end
end
