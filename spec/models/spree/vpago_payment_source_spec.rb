require 'spec_helper'

RSpec.describe Spree::VpagoPaymentSource, type: :model do
  describe 'associations' do
    it { should belong_to(:payment_method).optional }
    it { should have_one(:payment) }
  end

  describe '#actions' do
    let(:payment_source) { build(:payway_payment_source) }

    it 'returns available actions' do
      expect(payment_source.actions).to eq(%w[open_checkout process capture void cancel])
    end
  end

  describe '#can_open_checkout?' do
    let(:order) { create(:order) }
    let(:payment_method) { create(:payway_v2_gateway) }
    let(:params) { { payment_method_id: payment_method.id, payment_option: 'abapay_khqr' } }
    let!(:payment) { Vpago::Payments::FindOrCreate.call(order: order, params: params).value[:order].payments.first }
    let(:payment_source) { payment.source }

    context 'when payment is in checkout state' do
      before { payment.update!(state: 'checkout') }

      it 'returns true' do
        expect(payment_source.can_open_checkout?(payment)).to be true
      end
    end

    context 'when payment is not in checkout state' do
      before { payment.update!(state: 'processing') }

      it 'returns false' do
        expect(payment_source.can_open_checkout?(payment)).to be false
      end
    end
  end

  describe '#can_process?' do
    let(:order) { create(:order) }
    let(:payment_method) { create(:payway_v2_gateway) }
    let(:params) { { payment_method_id: payment_method.id, payment_option: 'abapay_khqr' } }
    let!(:payment) { Vpago::Payments::FindOrCreate.call(order: order, params: params).value[:order].payments.first }
    let(:payment_source) { payment.source }

    context 'when payment is in checkout state' do
      before { payment.update!(state: 'checkout') }

      it 'returns true' do
        expect(payment_source.can_process?(payment)).to be true
      end
    end

    context 'when payment is in processing state' do
      before { payment.update!(state: 'processing') }

      it 'returns true' do
        expect(payment_source.can_process?(payment)).to be true
      end
    end

    context 'when payment is completed' do
      before { payment.update!(state: 'completed') }

      it 'returns false' do
        expect(payment_source.can_process?(payment)).to be false
      end
    end

    context 'when payment is pending' do
      before { payment.update!(state: 'pending') }

      it 'returns false' do
        expect(payment_source.can_process?(payment)).to be false
      end
    end
  end

  describe '#can_capture?' do
    let(:order) { create(:order) }
    let(:payment_method) { create(:payway_v2_gateway) }
    let(:params) { { payment_method_id: payment_method.id, payment_option: 'abapay_khqr' } }
    let!(:payment) { Vpago::Payments::FindOrCreate.call(order: order, params: params).value[:order].payments.first }
    let(:payment_source) { payment.source }

    context 'when order is completed and payment is pending' do
      before do
        order.update!(state: 'complete', completed_at: Time.current)
        payment.update!(state: 'pending')
      end

      it 'returns true' do
        expect(payment_source.can_capture?(payment)).to be true
      end
    end

    context 'when order is not completed' do
      before do
        order.update!(state: 'payment')
        payment.update!(state: 'pending')
      end

      it 'returns false' do
        expect(payment_source.can_capture?(payment)).to be false
      end
    end

    context 'when payment is already completed' do
      before do
        order.update!(state: 'complete', completed_at: Time.current)
        payment.update!(state: 'completed')
      end

      it 'returns false' do
        expect(payment_source.can_capture?(payment)).to be false
      end
    end

    context 'when payment is not pending' do
      before do
        order.update!(state: 'complete', completed_at: Time.current)
        payment.update!(state: 'checkout')
      end

      it 'returns false' do
        expect(payment_source.can_capture?(payment)).to be false
      end
    end
  end

  describe '#can_cancel?' do
    let(:order) { create(:order) }
    let(:params) { { payment_method_id: payment_method.id, payment_option: 'abapay_khqr' } }
    let!(:payment) { Vpago::Payments::FindOrCreate.call(order: order, params: params).value[:order].payments.first }
    let(:payment_source) { payment.source }

    context 'with Vattanac Mini App payment' do
      let(:payment_method) { create(:vattanac_mini_app_gateway) }

      context 'when order is not completed and payment is completed' do
        before do
          order.update!(state: 'payment')
          payment.update!(state: 'completed')
        end

        it 'returns true' do
          expect(payment_source.can_cancel?(payment)).to be true
        end
      end

      context 'when order is completed' do
        before do
          order.update!(state: 'complete', completed_at: Time.current)
          payment.update!(state: 'completed')
        end

        it 'returns false' do
          expect(payment_source.can_cancel?(payment)).to be false
        end
      end

      context 'when payment is void' do
        before do
          order.update!(state: 'payment')
          payment.update!(state: 'void')
        end

        it 'returns false' do
          expect(payment_source.can_cancel?(payment)).to be false
        end
      end

      context 'when payment is not completed' do
        before do
          order.update!(state: 'payment')
          payment.update!(state: 'pending')
        end

        it 'returns false' do
          expect(payment_source.can_cancel?(payment)).to be false
        end
      end
    end

    context 'with True Money payment' do
      let(:payment_method) { create(:true_money_gateway) }

      context 'when order is not completed and payment is completed' do
        before do
          order.update!(state: 'payment')
          payment.update!(state: 'completed')
        end

        it 'returns true' do
          expect(payment_source.can_cancel?(payment)).to be true
        end
      end
    end

    context 'with non-cancelable payment method' do
      let(:payment_method) { create(:payway_v2_gateway) }

      before do
        order.update!(state: 'payment')
        payment.update!(state: 'completed')
      end

      it 'returns false' do
        expect(payment_source.can_cancel?(payment)).to be false
      end
    end
  end

  describe '#can_void?' do
    let(:order) { create(:order) }
    let(:payment_method) { create(:payway_v2_gateway) }
    let(:params) { { payment_method_id: payment_method.id, payment_option: 'abapay_khqr' } }
    let!(:payment) { Vpago::Payments::FindOrCreate.call(order: order, params: params).value[:order].payments.first }
    let(:payment_source) { payment.source }

    context 'when payment is pending' do
      before { payment.update!(state: 'pending') }

      it 'returns true' do
        expect(payment_source.can_void?(payment)).to be true
      end
    end

    context 'when payment is not pending' do
      before { payment.update!(state: 'completed') }

      it 'returns false' do
        expect(payment_source.can_void?(payment)).to be false
      end
    end
  end

  describe 'creating payment source via FindOrCreate service' do
    let(:order) { create(:order) }
    let(:payment_method) { create(:payway_v2_gateway) }
    let(:params) { { payment_method_id: payment_method.id, payment_option: 'abapay_khqr' } }

    context 'when creating a new payment with source' do
      it 'creates a payment source with correct attributes' do
        result = Vpago::Payments::FindOrCreate.call(order: order, params: params)

        expect(result.success?).to be true
        
        payment = order.payments.first
        source = payment.source

        expect(source).to be_a(Spree::VpagoPaymentSource)
        expect(source.payment_option).to eq('abapay_khqr')
        expect(source.payment_method_id).to eq(payment_method.id)
        expect(source.user_id).to eq(order.user&.id)
      end
    end

    context 'when finding existing payment source' do
      let!(:existing_payment) do
        Vpago::Payments::FindOrCreate.call(order: order, params: params).value[:order].payments.first
      end

      before do
        existing_payment.update!(state: 'checkout')
      end

      it 'reuses the existing payment source' do
        expect(order.payments.count).to eq(1)
        
        result = Vpago::Payments::FindOrCreate.call(order: order, params: params)

        expect(result.success?).to be true
        expect(order.payments.count).to eq(1)
        expect(order.payments.first.source.id).to eq(existing_payment.source.id)
      end
    end
  end
end
