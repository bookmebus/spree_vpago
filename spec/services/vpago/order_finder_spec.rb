require 'spec_helper'

RSpec.describe Vpago::OrderFinder do
  let(:order) { create(:order, number: 'R131576461') }

  describe '#find_and_verify!' do
    context 'when all params are valid' do
      let(:order_jwt_token) { Vpago::OrderUrlConstructor.new(order).send(:order_jwt_token) }
      let(:params_hash) { { order_number: order.number, order_jwt_token: order_jwt_token } }

      subject { described_class.new(params_hash) }

      it 'returns back the correct order' do
        expect(subject.find_and_verify!).to eq order
      end
    end

    context 'when order number is invalid' do
      let(:order_jwt_token) { Vpago::OrderUrlConstructor.new(order).send(:order_jwt_token) }
      let(:params_hash) { { order_number: 'INVALID', order_jwt_token: order_jwt_token } }

      subject { described_class.new(params_hash) }

      it 'raises record not found' do
        expect { subject.find_and_verify! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when jwt is invalid' do
      let(:params_hash) { { order_number: order.number, order_jwt_token: 'invalid-jwt' } }

      subject { described_class.new(params_hash) }

      it 'raises standard error' do
        expect { subject.find_and_verify! }.to raise_error(StandardError)
      end
    end
  end

  describe '#find_and_verify' do
    context 'when params are invalid' do
      let(:params_hash) { { order_number: order.number, order_jwt_token: 'invalid-jwt' } }

      subject { described_class.new(params_hash) }

      it 'rescues the error and returns nil' do
        expect { subject.find_and_verify! }.to raise_error(StandardError)
        expect(subject.find_and_verify).to eq nil
      end
    end
  end
end
