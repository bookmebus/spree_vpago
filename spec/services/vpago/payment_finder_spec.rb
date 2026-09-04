require 'spec_helper'

RSpec.describe Vpago::PaymentFinder do
  let(:order) { create(:order, number: 'R131576461') }
  let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order) }

  describe '#find_and_verify!' do
    context 'when all params is valid' do
      let(:order_jwt_token) { Vpago::PaymentUrlConstructor.new(payment).send(:order_jwt_token) }
      let(:params_hash) { { order_number: order.number, payment_number: payment.number, order_jwt_token: order_jwt_token } }

      subject { described_class.new(params_hash) }

      it 'return back correct payment' do
        expect(subject.find_and_verify!).to eq payment
      end
    end

    context 'when order number or payment number is invalid' do
      let(:order_jwt_token) { Vpago::PaymentUrlConstructor.new(payment).send(:order_jwt_token) }
      let(:params_hash) { { order_number: 'INVALID', payment_number: payment.number, order_jwt_token: order_jwt_token } }

      subject { described_class.new(params_hash) }

      it 'raise record not found' do
        expect { subject.find_and_verify! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when jwt is invalid' do
      let(:order_jwt_token) { Vpago::PaymentUrlConstructor.new(payment).send(:order_jwt_token) }
      let(:params_hash) { { order_number: order.number, payment_number: payment.number, order_jwt_token: 'invalid-jwt' } }

      subject { described_class.new(params_hash) }

      it 'raise standard error' do
        expect { subject.find_and_verify! }.to raise_error(StandardError)
      end
    end
  end

  describe '#find_and_verify' do
    context 'when params is invalid' do
      let(:order_jwt_token) { Vpago::PaymentUrlConstructor.new(payment).send(:order_jwt_token) }
      let(:params_hash) { { order_number: order.number, payment_number: payment.number, order_jwt_token: 'invalid-jwt' } }

      subject { described_class.new(params_hash) }

      it 'rescue the errors and return payment nil' do
        expect { subject.find_and_verify! }.to raise_error(StandardError)
        expect(subject.find_and_verify).to eq nil
      end
    end
  end
end
