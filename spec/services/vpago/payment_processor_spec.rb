require 'spec_helper'

RSpec.describe Vpago::PaymentProcessor do
  let(:user_informer) { ::Vpago::UserInformers::Firebase.new(payment.order) }

  let(:order) { create(:order) }
  let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order) }

  subject { described_class.new(payment: payment) }

  before do
    allow(subject).to receive(:user_informer).and_return(user_informer)
  end

  describe '#call' do
    context 'when payment is paid' do
      it 'process_payment then process_order' do
        allow(payment).to receive(:completed?).and_return(true)

        expect(subject).to receive(:process_payment!)
        expect(subject).to receive(:process_order)

        subject.call
      end
    end

    context 'when payment is not paid' do
      it 'process_payment then mark it as failed instead of continue process_order' do
        allow(payment).to receive(:completed?).and_return(false)
        allow(payment).to receive(:pending?).and_return(false)

        expect(subject).to receive(:process_payment!)
        expect(subject).to receive(:mark_payment_process_failed)

        expect(subject).not_to receive(:process_order)

        subject.call
      end
    end

    context 'when process_payment! raise Spree::Core::GatewayError or StateMachines::InvalidTransition' do
      it 'rescue the error & mark process_payment failed' do
        allow(subject).to receive(:process_payment!).and_raise(Spree::Core::GatewayError.new('gateway_error'))

        expect(subject).to receive(:mark_payment_process_failed).with('gateway_error')

        subject.call
      end
    end
  end

  describe '#process_payment!' do
    it 'inform user that payment is processing & trigger payment.process!' do
      expect(user_informer).to receive(:payment_is_processing).with(processing: true)
      expect(payment).to receive(:process!)

      subject.send(:process_payment!)
    end
  end

  # more details how how completer work, we should check complete spec instead.
  describe '#process_order' do
    let(:completer) { Spree::Checkout::Complete.new }

    context 'when completer success' do 
      before do
        allow(Spree::Checkout::Complete).to receive(:new).and_return(completer)
        allow(completer).to receive(:success?).and_return(true)
      end

      it 'inform user that order is processing, trigger completer & mark_order_process_completed' do
        expect(user_informer).to receive(:order_is_processing).with(processing: true)
        expect(completer).to receive(:call).with(order: payment.order).and_return(completer)
        expect(subject).to receive(:mark_order_process_completed)
  
        subject.send(:process_order)
      end
    end

    context 'when completer failed' do 
      before do
        allow(Spree::Checkout::Complete).to receive(:new).and_return(completer)
        allow(completer).to receive(:success?).and_return(false)
        allow(completer).to receive(:error).and_return('this-is-error')
      end

      it 'inform user that order is processing, trigger completer & mark_order_process_failed' do
        expect(user_informer).to receive(:order_is_processing).with(processing: true)
        expect(completer).to receive(:call).with(order: payment.order).and_return(completer)
        expect(subject).to receive(:mark_order_process_failed).with('this-is-error')
  
        subject.send(:process_order)
      end
    end
  end

  describe '#mark_order_process_completed' do
    context 'when pre-auth enabled or payment is authorized' do
      before do
        allow(payment).to receive(:pending?).and_return(true)
      end

      it 'capture the payment & inform user the order is completed!' do
        expect(payment).to receive(:capture!)
        expect(user_informer).to receive(:order_is_completed).with(processing: false)

        subject.send(:mark_order_process_completed)
      end
    end

    context 'when pre-auth is disabled' do
      before do
        allow(payment).to receive(:pending?).and_return(false)
      end

      it 'inform user the order is completed directly' do
        expect(payment).not_to receive(:capture!)
        expect(user_informer).to receive(:order_is_completed).with(processing: false)

        subject.send(:mark_order_process_completed)
      end
    end
  end

  describe '#mark_order_process_failed' do
    context 'when pre-auth enabled or payment is authorized' do
      before do
        allow(payment).to receive(:pending?).and_return(true)
      end

      it 'inform user that process order failed & refund amount back to user' do
        expect(user_informer).to receive(:order_process_failed).with(processing: true, log_message: 'this-is-log-message')
        expect(payment).to receive(:void_transaction!)
        expect(user_informer).to receive(:payment_is_refunded).with(processing: false)

        subject.send(:mark_order_process_failed, 'this-is-log-message')
      end
    end

    context 'when pre-auth is disabled' do
      before do
        allow(payment).to receive(:pending?).and_return(false)
      end

      it 'only inform user that process order failed' do
        expect(user_informer).to receive(:order_process_failed).with(processing: false, log_message: 'this-is-log-message')

        # when pre-auth disabled, we can't refund amount back to user. so these methods are not called.
        expect(payment).not_to receive(:void_transaction!)
        expect(user_informer).not_to receive(:payment_is_refunded)

        subject.send(:mark_order_process_failed, 'this-is-log-message')
      end
    end
  end
end