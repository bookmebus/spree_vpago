require 'spec_helper'

RSpec.describe Vpago::Vattanac::PaymentRequestUpdater, type: :model do
  let(:gateway) { create(:vattanac_gateway, auto_capture: true) }
  let(:payment_source) { create(:payway_payment_source, payment_method: gateway) }
  let(:user) { create(:user) }
  let(:order) { OrderWalkthrough.up_to(:payment) }
  let(:payment) { create(:vattanac_payment, payment_method: gateway, source: payment_source, order: order, state: 'processing') }
  let(:options) { { updated_by_user_id: user.id, updated_reason: Spree.t('vpago.payments.checker_updated_by_description') } }

  subject(:updater) { described_class.new(payment, options) }

  describe 'ineligible items' do
    it 'marks the payment as failed due to insufficient stock without calling the gateway' do
      allow(order.line_items).to receive(:all?).and_return(false)
      expect(gateway).not_to receive(:check_transaction)

      updater.call

      expect(payment.state).to eq('failed')
      expect(payment.source.payment_description).to eq('Items are not eligible due to insufficient stock')
    end
  end

  describe 'gateway timeout' do
    it 'leaves the payment untouched instead of marking it failed' do
      allow(gateway).to receive(:check_transaction).and_raise(Faraday::TimeoutError)

      expect { updater.call }.not_to raise_error
      expect(payment.reload.state).to eq('processing')
    end
  end

  describe '#call' do
    context 'when the transaction succeeds' do
      it 'clears the error message and marks the payment as successful' do
        checker = double(:vattanac_status_checker, success?: true, failed?: false)
        allow(gateway).to receive(:check_transaction).with(payment).and_return(checker)

        marker = double(:marker)
        expect(::Vpago::PaymentStatusMarker).to receive(:new)
          .with(payment, options.merge(status: true, description: nil))
          .and_return(marker)
        expect(marker).to receive(:call)

        updater.call

        expect(updater.error_message).to be_nil
      end
    end

    context 'when the transaction fails' do
      it 'records the gateway error message and marks the payment as failed' do
        checker = double(:vattanac_status_checker, success?: false, failed?: true, error_message: 'Transaction not found')
        allow(gateway).to receive(:check_transaction).with(payment).and_return(checker)

        marker = double(:marker)
        expect(::Vpago::PaymentStatusMarker).to receive(:new)
          .with(payment, options.merge(status: false, description: 'Transaction not found'))
          .and_return(marker)
        expect(marker).to receive(:call)

        updater.call

        expect(updater.error_message).to eq('Transaction not found')
      end
    end

    context 'when the transaction is still processing' do
      it 'does not mark the payment as either success or failure' do
        checker = double(:vattanac_status_checker, success?: false, failed?: false)
        allow(gateway).to receive(:check_transaction).with(payment).and_return(checker)

        expect(::Vpago::PaymentStatusMarker).not_to receive(:new)

        updater.call
      end
    end

    context 'when the transaction fails and ignore_on_failed is set' do
      let(:options) { { updated_by_user_id: user.id, ignore_on_failed: true } }

      it 'does not mark the payment as failed' do
        checker = double(:vattanac_status_checker, success?: false, failed?: true, error_message: 'Transaction not found')
        allow(gateway).to receive(:check_transaction).with(payment).and_return(checker)

        expect(::Vpago::PaymentStatusMarker).not_to receive(:new)

        updater.call
      end
    end

    context 'when the order is already paid' do
      it 'does not call the gateway' do
        allow(order).to receive(:paid?).and_return(true)
        expect(gateway).not_to receive(:check_transaction)

        updater.call
      end
    end
  end
end
