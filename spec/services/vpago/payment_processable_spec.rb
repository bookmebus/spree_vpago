require 'spec_helper'

RSpec.describe Vpago::PaymentProcessable do
  include ActiveJob::TestHelper

  let(:user_informer) { ::Vpago::UserInformers::Firebase.new(payment.order) }

  let(:order) { create(:order_with_line_items, state: :payment) }
  let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order) }

  # payment processor include this module.
  subject { Vpago::PaymentProcessor.new(payment: payment) }

  before do
    allow(subject).to receive(:user_informer).and_return(user_informer)
  end

  describe '#enqueue_capture_payment_if_available!' do
    context 'when capture action is available' do
      it 'enqueues PaymentCapturerJob' do
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_capture?).and_return(true)

        expect(Vpago::PaymentCapturerJob).to receive(:perform_later).with(payment.id)

        subject.send(:enqueue_capture_payment_if_available!)
      end
    end

    context 'when capture action is not available' do
      it 'does not enqueue PaymentCapturerJob' do
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_capture?).and_return(false)

        expect(Vpago::PaymentCapturerJob).not_to receive(:perform_later)

        subject.send(:enqueue_capture_payment_if_available!)
      end
    end
  end

  describe '#enqueue_void_or_cancel_payment_if_available!' do
    context 'when void action is available' do
      it 'enqueues PaymentVoiderJob' do
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_void?).and_return(true)
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_cancel?).and_return(false)

        expect(Vpago::PaymentVoiderJob).to receive(:perform_later).with(payment.id)
        expect(Vpago::PaymentCancelerJob).not_to receive(:perform_later)

        subject.send(:enqueue_void_or_cancel_payment_if_available!)
      end
    end

    context 'when cancel action is available' do
      it 'enqueues PaymentCancelerJob' do
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_void?).and_return(false)
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_cancel?).and_return(true)

        expect(Vpago::PaymentVoiderJob).not_to receive(:perform_later)
        expect(Vpago::PaymentCancelerJob).to receive(:perform_later).with(payment.id)

        subject.send(:enqueue_void_or_cancel_payment_if_available!)
      end
    end

    context 'when neither void nor cancel action is available' do
      it 'does not enqueue any job' do
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_void?).and_return(false)
        allow_any_instance_of(Spree::VpagoPaymentSource).to receive(:can_cancel?).and_return(false)

        expect(Vpago::PaymentVoiderJob).not_to receive(:perform_later)
        expect(Vpago::PaymentCancelerJob).not_to receive(:perform_later)

        subject.send(:enqueue_void_or_cancel_payment_if_available!)
      end
    end
  end

  describe '#extract_completer_failure_reason_code' do
    context 'when some items are out of stock' do      
      before do
        allow_any_instance_of(Spree::LineItem).to receive(:sufficient_stock?).and_return(false)
      end

      it 'returns reason code :some_line_items_are_out_of_stock' do
        completer = Spree::Checkout::Complete.new.call(order: order)
        expect(subject.send(:extract_completer_failure_reason_code, completer.error)).to eq :some_line_items_are_out_of_stock
      end
    end

    context 'when some items are discontinued' do      
      before do
        allow_any_instance_of(Spree::Variant).to receive(:discontinued?).and_return(true)
      end

      it 'returns reason code :some_variants_are_discontinued' do
        completer = Spree::Checkout::Complete.new.call(order: order)
        expect(subject.send(:extract_completer_failure_reason_code, completer.error)).to eq :some_variants_are_discontinued
      end
    end

    context 'when error message is neither of above cases' do
      it 'returns reason code :unable_to_complete_order' do
        expect(subject.send(:extract_completer_failure_reason_code, { :base => nil })).to eq :unable_to_complete_order
        expect(subject.send(:extract_completer_failure_reason_code, '')).to eq :unable_to_complete_order
        expect(subject.send(:extract_completer_failure_reason_code, {})).to eq :unable_to_complete_order
        expect(subject.send(:extract_completer_failure_reason_code, nil)).to eq :unable_to_complete_order
      end
    end
  end

  describe '#available_actions' do
    it 'returns payment actions' do
      expect(payment).to receive(:actions).and_return(['process', 'capture'])

      result = subject.send(:available_actions)

      expect(result).to eq(['process', 'capture'])
    end
  end

  describe '#success?' do
    it 'returns true when no error' do
      expect(subject.success?).to be true
    end

    it 'returns false when there is an error' do
      subject.send(:failure, 'Some error')
      expect(subject.success?).to be false
    end
  end

  describe '#failure' do
    it 'sets the error' do
      subject.send(:failure, 'Some error message')
      expect(subject.success?).to be false
      expect(subject.instance_variable_get(:@error)).to eq 'Some error message'
    end
  end
end
