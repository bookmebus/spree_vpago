require 'spec_helper'

RSpec.describe Vpago::Payments::FindOrCreate do
  describe '.call' do
    context 'when no valid payment exist' do
      let(:order) { create(:order) }
      let(:method) { create(:payway_v2_gateway) }
      let(:params) { { payment_method_id: method.id, source_attributes: { payment_option: 'abapay_khqr' } } }
  
      let(:existing_payment) { described_class.call(order: order, params: params).value[:order].payments.first }

      before do
        existing_payment.update(state: :failed)
      end
  
      it 'create new payment with source' do
        expect(order.payments.length).to eq 1

        result = described_class.call(order: order, params: params)

        expect(result.success?)
        expect(order.payments.length).to eq 2
        expect(order.payments[1].id).not_to eq existing_payment.id
        expect(order.payments[1].source.class).to eq method.payment_source_class
      end
    end

    context 'when checkout payment exist' do
      let(:order) { create(:order) }
      let(:method) { create(:payway_v2_gateway) }
      let(:params) { { payment_method_id: method.id, source_attributes: { payment_option: 'abapay_khqr' } } }
      let(:existing_payment) { described_class.call(order: order, params: params).value[:order].payments.first }
  
      before do
        existing_payment.update(state: :checkout)
      end

      it 'return existing payment' do
        expect(order.payments.length).to eq 1

        result = described_class.call(order: order, params: params)

        expect(result.success?)
        expect(order.payments.length).to eq 1
        expect(order.payments[0].id).to eq existing_payment.id
        expect(order.payments[0].source.class).to eq method.payment_source_class
      end
    end
  end
end