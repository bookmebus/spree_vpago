require 'spec_helper'

RSpec.describe Vpago::PaymentProcessor do
  include ActiveJob::TestHelper

  let(:user_informer) { ::Vpago::UserInformers::Firebase.new(payment.order) }

  let(:order) { create(:order_with_line_items, state: :payment) }
  let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order) }

  subject { described_class.new(payment: payment) }

  before do
    allow(subject).to receive(:user_informer).and_return(user_informer)
  end

  describe '#call' do
    context 'when process action is not available' do
      it 'skips process_payment! && calls process_order!' do
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_process?).and_return(false)
        allow(payment).to receive(:completed?).and_return(true)

        expect(subject).not_to receive(:process_payment!)
        expect(subject).to receive(:process_order!)

        subject.call
      end
    end

    context 'when process action is available and payment becomes completed' do
      it 'calls process_payment! then process_order!' do
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_process?).and_return(true)

        # Simulate process_payment! changing payment state to completed
        allow(subject).to receive(:process_payment!) do
          allow(payment).to receive(:completed?).and_return(true)
        end

        expect(subject).to receive(:process_payment!)
        expect(subject).to receive(:process_order!)

        subject.call
      end
    end

    context 'when process action is available and payment becomes pending' do
      it 'calls process_payment! then process_order!' do
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_process?).and_return(true)
        allow(payment).to receive(:completed?).and_return(false)
        allow(payment).to receive(:pending?).and_return(false, true)

        allow(subject).to receive(:process_payment!)

        expect(subject).to receive(:process_payment!)
        expect(subject).to receive(:process_order!)

        subject.call
      end
    end

    context 'when process action is available but payment state does not change' do
      it 'calls process_payment! but does not call process_order!' do
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_process?).and_return(true)
        allow(payment).to receive(:completed?).and_return(false)
        allow(payment).to receive(:pending?).and_return(false)

        allow(subject).to receive(:process_payment!)

        expect(subject).to receive(:process_payment!)
        expect(subject).not_to receive(:process_order!)

        subject.call
      end
    end

    context 'when process_payment! raises Spree::Core::GatewayError with gateway message' do
      it 'calls payment_is_retrying and re-raises the error' do
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_process?).and_return(true)
        allow(subject).to receive(:process_payment!).and_raise(Spree::Core::GatewayError.new(Spree.t(:unable_to_connect_to_gateway)))

        expect(user_informer).to receive(:payment_is_retrying).with(processing: true)

        expect { subject.call }.to raise_error(Spree::Core::GatewayError)
      end
    end

    context 'when process_payment! raises Spree::Core::GatewayError with other message' do
      it 'calls handle_payment_failure with gateway_error' do
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_process?).and_return(true)
        allow(subject).to receive(:process_payment!).and_raise(Spree::Core::GatewayError.new('Some other error'))

        expect(subject).to receive(:handle_payment_failure).with(:gateway_error, 'Some other error')

        subject.call
      end
    end

    context 'when process_payment! raises StateMachines::InvalidTransition' do
      it 'calls handle_payment_failure with invalid_state_machine_transition' do
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_process?).and_return(true)

        # Mock payment.process! to raise InvalidTransition (simulating invalid state)
        allow(subject).to receive(:process_payment!).and_raise(StateMachines::InvalidTransition.new(payment, Spree::Payment.state_machines[:state], :void))

        expect(subject).to receive(:handle_payment_failure).with(:invalid_state_machine_transition, anything)

        subject.call
      end
    end
  end

  describe '#process_payment!' do
    it 'informs user that payment is processing & triggers payment.process!' do
      expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#process_payment! for payment_number: #{payment.number} with args: \[]")).once
      expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#process_payment! for payment_number: #{payment.number} in")).once

      expect(user_informer).to receive(:payment_is_processing).with(processing: true)
      expect(payment).to receive(:process!)

      subject.send(:process_payment!)
    end
  end

  describe '#process_order!' do
    let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order, state: :completed) }
    let(:completer) { Spree::Checkout::Complete.new }

    before do
      allow(Spree::Checkout::Complete).to receive(:new).and_return(completer)
    end
    
    context 'when completer success' do
      it 'inform user that order is processing, trigger completer & handle_order_process_completed' do
        expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#process_order! for payment_number: #{payment.number} with args: \[]")).once
        expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#process_order! for payment_number: #{payment.number} in")).once

        expect(user_informer).to receive(:order_is_processing).with(processing: true)
        expect(completer).to receive(:call).with(order: payment.order).and_call_original
        expect(subject).to receive(:handle_order_process_completed)
  
        subject.send(:process_order!)
      end
    end

    context 'when completer failed because items is out of stock' do 
      before do
        allow_any_instance_of(Spree::LineItem).to receive(:sufficient_stock?).and_return(false)
      end

      it 'inform user that order is processing, trigger completer & handle_order_process_failure with out of stock message' do
        expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#process_order! for payment_number: #{payment.number} with args: \[]")).once
        expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#process_order! for payment_number: #{payment.number} in")).once

        expect(user_informer).to receive(:order_is_processing).with(processing: true)
        expect(completer).to receive(:call).with(order: payment.order).and_call_original
        expect(subject).to receive(:handle_order_process_failure).with(:some_line_items_are_out_of_stock, Spree.t(:insufficient_stock_lines_present))
  
        subject.send(:process_order!)
      end
    end

    context 'when completer failed because items is discontinued' do 
      before do
        allow_any_instance_of(Spree::Variant).to receive(:discontinued?).and_return(true)
      end

      it 'inform user that order is processing, trigger completer & handle_order_process_failure with discountinued message' do
        expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#process_order! for payment_number: #{payment.number} with args: \[]")).once
        expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#process_order! for payment_number: #{payment.number} in")).once

        expect(user_informer).to receive(:order_is_processing).with(processing: true)
        expect(completer).to receive(:call).with(order: payment.order).and_call_original
        expect(subject).to receive(:handle_order_process_failure).with(:some_variants_are_discontinued, Spree.t(:discontinued_variants_present))
  
        subject.send(:process_order!)
      end
    end
  end

  describe '#handle_order_process_completed' do
    it 'enqueues capture payment if available and informs user order is completed' do
      expect(subject).to receive(:enqueue_capture_payment_if_available!)
      expect(user_informer).to receive(:order_is_completed).with(processing: false)

      subject.send(:handle_order_process_completed)
      expect(subject.success?).to be true
    end
  end

  describe '#handle_order_process_failure' do
    it 'informs user of failure, enqueues cancel/release, and marks as failure' do
      expect(user_informer).to receive(:order_process_failed).with(
        processing: false,
        reason_code: :some_line_items_are_out_of_stock,
        reason_message: 'Out of stock'
      )
      expect(subject).to receive(:enqueue_void_or_cancel_payment_if_available!)

      subject.send(:handle_order_process_failure, :some_line_items_are_out_of_stock, 'Out of stock')
      expect(subject.success?).to be false
    end
  end

  describe '#handle_payment_failure' do
    it 'informs user of failure, enqueues cancel/release, and marks as failure' do
      expect(user_informer).to receive(:payment_process_failed).with(
        processing: false,
        reason_code: :gateway_error,
        reason_message: 'Payment gateway error'
      )
      expect(subject).to receive(:enqueue_void_or_cancel_payment_if_available!)

      subject.send(:handle_payment_failure, :gateway_error, 'Payment gateway error')
      expect(subject.success?).to be false
    end
  end
end
