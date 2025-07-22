require 'spec_helper'

RSpec.describe Vpago::PaymentUrlConstructor do
  let(:order) { create(:order, number: 'R322092410', token: 'ry9yYKOGP64e_VVDk8-zZA1705211585402') }
  let!(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order) }

  subject { described_class.new(payment) }

  describe '#checkout_url' do
    it { expect(subject.checkout_url).to eq "http://localhost:4000/vpago_payments/checkout?order_jwt_token=#{subject.send(:order_jwt_token)}&order_number=R322092410&payment_number=PJ0MYD2Y&platform=app" }
  end

  describe '#processing_url' do
    it { expect(subject.processing_url).to eq "http://localhost:4000/vpago_payments/processing?order_jwt_token=#{subject.send(:order_jwt_token)}&order_number=R322092410&payment_number=PJ0MYD2Y" }
  end

  describe '#success_url' do
    it { expect(subject.success_url).to eq "http://localhost:4000/vpago_payments/success?order_jwt_token=#{subject.send(:order_jwt_token)}&order_number=R322092410&payment_number=PJ0MYD2Y" }
  end

  describe '#process_payment_url' do
    it { expect(subject.process_payment_url).to eq "http://localhost:4000/vpago_payments/process_payment?order_jwt_token=#{subject.send(:order_jwt_token)}&order_number=R322092410&payment_number=PJ0MYD2Y" }
  end

  describe '#query' do
    it { expect(subject.query).to eq "order_jwt_token=#{subject.send(:order_jwt_token)}&order_number=R322092410&payment_number=PJ0MYD2Y" }
  end

  describe '#order_jwt_token' do
    it 'return encoded JWT of order number with token' do
      payload = { order_number: order.number, order_id: order.id }
      expect(subject.send(:order_jwt_token)).to eq JWT.encode(payload, order.token, 'HS256')
    end
  end
end