require 'spec_helper'

RSpec.describe Vpago::OrderProcessor do
  let(:user_informer) { ::Vpago::UserInformers::Firebase.new(order) }
  let(:order) { create(:order_with_line_items, state: :payment) }

  subject { described_class.new(order: order) }

  before do
    allow(subject).to receive(:user_informer).and_return(user_informer)
  end

  describe '#call' do
    context 'when process_order! raises StateMachines::InvalidTransition' do
      it 'calls handle_order_process_failure with invalid_state_machine_transition' do
        allow(subject).to receive(:process_order!).and_raise(
          StateMachines::InvalidTransition.new(order, Spree::Order.state_machines[:state], :cancel)
        )

        expect(subject).to receive(:handle_order_process_failure).with(:invalid_state_machine_transition, anything)

        subject.call
      end
    end
  end

  describe '#process_order!' do
    let(:completer) { Spree::Checkout::Complete.new }

    before do
      allow(Spree::Checkout::Complete).to receive(:new).and_return(completer)
      # Mirrors the real order_total_after_store_credit == 0 scenario this processor exists for --
      # no payment is expected, so the order completes without one.
      allow(order).to receive(:payment_required?).and_return(false)
    end

    context 'when completer succeeds' do
      it 'informs user that order is processing, triggers completer & handle_order_process_completed' do
        expect(VpagoLogger).to receive(:log).with(
          label: 'Vpago::OrderProcessor#process_order!',
          data: { order_number: order.number, args: [] }
        ).and_call_original

        expect(user_informer).to receive(:order_is_processing).with(processing: true)
        expect(completer).to receive(:call).with(order: order).and_call_original
        expect(subject).to receive(:handle_order_process_completed)

        subject.send(:process_order!)
      end
    end

    context 'when completer fails because items are out of stock' do
      before do
        allow_any_instance_of(Spree::LineItem).to receive(:sufficient_stock?).and_return(false)
      end

      it 'informs user that order is processing, triggers completer & handle_order_process_failure with out of stock message' do
        expect(user_informer).to receive(:order_is_processing).with(processing: true)
        expect(completer).to receive(:call).with(order: order).and_call_original
        expect(subject).to receive(:handle_order_process_failure).with(:some_line_items_are_out_of_stock, Spree.t(:insufficient_stock_lines_present))

        subject.send(:process_order!)
      end
    end

    context 'when completer fails because items are discontinued' do
      before do
        allow_any_instance_of(Spree::Variant).to receive(:discontinued?).and_return(true)
      end

      it 'informs user that order is processing, triggers completer & handle_order_process_failure with discontinued message' do
        expect(user_informer).to receive(:order_is_processing).with(processing: true)
        expect(completer).to receive(:call).with(order: order).and_call_original
        expect(subject).to receive(:handle_order_process_failure).with(:some_variants_are_discontinued, Spree.t(:discontinued_variants_present))

        subject.send(:process_order!)
      end
    end
  end

  describe '#handle_order_process_completed' do
    it 'informs user order is completed' do
      expect(user_informer).to receive(:order_is_completed).with(processing: false)

      subject.send(:handle_order_process_completed)
      expect(subject.success?).to be true
    end
  end

  describe '#handle_order_process_failure' do
    it 'informs user of failure and marks as failure' do
      expect(user_informer).to receive(:order_process_failed).with(
        processing: false,
        reason_code: :some_line_items_are_out_of_stock,
        reason_message: 'Out of stock'
      )

      subject.send(:handle_order_process_failure, :some_line_items_are_out_of_stock, 'Out of stock')
      expect(subject.success?).to be false
    end
  end
end
