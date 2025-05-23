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
    context 'when payment is completed' do
      it 'process_payment! then process_order!' do
        expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#call! for payment_number: #{payment.number} with args: \[]")).once
        expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#call! for payment_number: #{payment.number} in")).once

        allow(payment).to receive(:completed?).and_return(true)

        expect(subject).to receive(:process_payment!)
        expect(subject).to receive(:process_order!)

        subject.call
      end
    end

    context 'when payment is not completed' do
      it 'did not call process_order!' do
        expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#call! for payment_number: #{payment.number} with args: \[]")).once
        expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#call! for payment_number: #{payment.number} in")).once

        allow(payment).to receive(:completed?).and_return(false)
        allow(payment).to receive(:pending?).and_return(false)

        expect(subject).to receive(:process_payment!)
        expect(subject).not_to receive(:process_order!)

        subject.call
      end
    end

    context 'when process_payment! raise Spree::Core::GatewayError or StateMachines::InvalidTransition' do
      it 'rescue the error & call handle_payment_failure' do
        expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#call! for payment_number: #{payment.number} with args: \[]")).once
        expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#call! for payment_number: #{payment.number} in")).once

        allow(subject).to receive(:process_payment!).and_raise(Spree::Core::GatewayError.new('This is error'))

        expect(subject).to receive(:handle_payment_failure).with(:gateway_error, 'This is error')

        subject.call
      end
    end

    context 'when process_payment! raise Spree::Core::GatewayError connecting to gateway' do
      it 'rescue the error & call handle_payment_failure' do
        expect(user_informer).to receive(:payment_is_processing).with(processing: true)
        expect(subject).to receive(:handle_payment_failure).with(:unable_to_connect_to_gateway, 'Unable to connect to gateway.')

        VCR.use_cassette("connection_error") do
          subject.call
        end
      end
    end
  end

  describe '#process_payment!' do
    context 'when payment is completed?' do
      it 'inform user that payment is processing & trigger payment.process!' do
        expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#process_payment! for payment_number: #{payment.number} with args: \[]")).once
        expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#process_payment! for payment_number: #{payment.number} in")).once

        expect(user_informer).to receive(:payment_is_processing).with(processing: true)
        expect(payment).to receive(:process!)

        allow(payment).to receive(:completed?).and_return(true)

        subject.send(:process_payment!)
      end
    end

    context 'when payment is pending?' do
      it 'inform user that payment is processing & trigger payment.process!' do
        expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#process_payment! for payment_number: #{payment.number} with args: \[]")).once
        expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#process_payment! for payment_number: #{payment.number} in")).once

        expect(user_informer).to receive(:payment_is_processing).with(processing: true)
        expect(payment).to receive(:process!)

        allow(payment).to receive(:pending?).and_return(true)

        subject.send(:process_payment!)
      end
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
    context 'when pre-auth enabled or payment is authorized' do
      before do
        allow_any_instance_of(Spree::Payment).to receive(:pending?).and_return(true)
      end

      it 'capture the payment in job & inform user the order is completed!' do
        expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#handle_order_process_completed for payment_number: #{payment.number} with args: \[]")).once
        expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#handle_order_process_completed for payment_number: #{payment.number} in")).once

        expect(Vpago::PaymentCapturerJob).to receive(:perform_now).with(payment.id).and_call_original
        expect(user_informer).to receive(:order_is_completed).with(processing: false)
        
        perform_enqueued_jobs do
          expect(payment.state).to eq 'checkout'
          subject.send(:handle_order_process_completed)
          expect(payment.reload.state).to eq 'completed'
        end
      end
    end

    context 'when pre-auth is disabled' do
      before do
        allow(payment).to receive(:pending?).and_return(false)
      end

      it 'inform user the order is completed directly' do
        expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#handle_order_process_completed for payment_number: #{payment.number} with args: \[]")).once
        expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#handle_order_process_completed for payment_number: #{payment.number} in")).once

        expect(payment).not_to receive(:capture!)
        expect(user_informer).to receive(:order_is_completed).with(processing: false)

        subject.send(:handle_order_process_completed)
        expect(subject.success?).to be true
      end
    end
  end

  describe '#handle_order_process_failure' do
    context 'when can_cancel_pre_auth (pre-auth is enabled)' do
      before do
        allow(subject).to receive(:can_cancel_pre_auth?).and_return(true)
      end

      it 'inform user that process order failed & call cancel_pre_auth' do
        expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#handle_order_process_failure for payment_number: #{payment.number} with args: [:some_line_items_are_out_of_stock, \"My error message\"]")).once
        expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#handle_order_process_failure for payment_number: #{payment.number} in")).once

        expect(user_informer).to receive(:order_process_failed).with(processing: true, reason_code: :some_line_items_are_out_of_stock, reason_message: 'My error message')
        expect(subject).to receive(:cancel_pre_auth).with(:some_line_items_are_out_of_stock, 'My error message')

        subject.send(:handle_order_process_failure, :some_line_items_are_out_of_stock, 'My error message')
        expect(subject.success?).to be false
      end
    end

    context 'when can_cancel_pre_auth? false (pre-auth is disabled)' do
      before do
        allow(subject).to receive(:can_cancel_pre_auth?).and_return(false)
      end

      it 'inform user that process order failed & not calling cancel_pre_auth' do
        expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#handle_order_process_failure for payment_number: #{payment.number} with args: [:some_line_items_are_out_of_stock, \"Out of stock\"]")).once
        expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#handle_order_process_failure for payment_number: #{payment.number} in")).once

        expect(user_informer).to receive(:order_process_failed).with(processing: false, reason_code: :some_line_items_are_out_of_stock, reason_message: 'Out of stock')
        expect(subject).not_to receive(:cancel_pre_auth)

        subject.send(:handle_order_process_failure, :some_line_items_are_out_of_stock, 'Out of stock')
        expect(subject.success?).to be false
      end
    end
  end

  describe '#handle_payment_failure' do
    context 'when can_cancel_pre_auth (pre-auth is enabled)' do
      before do
        allow(subject).to receive(:can_cancel_pre_auth?).and_return(true)
      end

      it 'inform user that payment process failed & call cancel_pre_auth' do
        expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#handle_payment_failure for payment_number: #{payment.number} with args: [:some_line_items_are_out_of_stock, \"My error message\"]")).once
        expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#handle_payment_failure for payment_number: #{payment.number} in")).once

        expect(user_informer).to receive(:payment_process_failed).with(processing: true, reason_code: :some_line_items_are_out_of_stock, reason_message: 'My error message')
        expect(subject).to receive(:cancel_pre_auth).with(:some_line_items_are_out_of_stock, 'My error message')

        subject.send(:handle_payment_failure, :some_line_items_are_out_of_stock, 'My error message')
        expect(subject.success?).to be false
      end
    end

    context 'when can_cancel_pre_auth? false (pre-auth is disabled)' do
      before do
        allow(subject).to receive(:can_cancel_pre_auth?).and_return(false)
      end

      it 'inform user that payment process failed & not calling cancel_pre_auth' do
        expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#handle_payment_failure for payment_number: #{payment.number} with args: [:some_line_items_are_out_of_stock, \"My error message\"]")).once
        expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#handle_payment_failure for payment_number: #{payment.number} in")).once

        expect(user_informer).to receive(:payment_process_failed).with(processing: false, reason_code: :some_line_items_are_out_of_stock, reason_message: 'My error message')
        expect(subject).not_to receive(:cancel_pre_auth)

        subject.send(:handle_payment_failure, :some_line_items_are_out_of_stock, 'My error message')
        expect(subject.success?).to be false
      end
    end
  end

  describe '#cancel_pre_auth' do
    it 'call void_transaction! & alert to user that payment is refunded' do
      expect(Rails.logger).to receive(:error).with(start_with("Started Vpago::PaymentProcessor#cancel_pre_auth for payment_number: #{payment.number} with args: \[]")).once
      expect(Rails.logger).to receive(:error).with(start_with("Completed Vpago::PaymentProcessor#cancel_pre_auth for payment_number: #{payment.number} in")).once

      expect(payment).to receive(:void_transaction!)
      expect(user_informer).to receive(:payment_is_refunded).with(processing: false, reason_code: :some_line_items_are_out_of_stock, reason_message: 'My error message')

      subject.send(:cancel_pre_auth, :some_line_items_are_out_of_stock, 'My error message')
    end
  end

  describe '#can_cancel_pre_auth?' do
    context 'when payment is pending (which mean pre-auth enabled & money is authorized)' do
      let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order, state: :pending) }

      it 'return true' do
        expect(payment.pending?).to be true
        expect(subject.send(:can_cancel_pre_auth?)).to be true
      end
    end

    context 'pre-auth is enabled' do
      let(:payment_method) { create(:payway_v2_gateway, enable_pre_auth: true, preferred_public_key: 'THIS IS PRE-AUTH KEY') }
      let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order, state: :checkout, payment_method: payment_method) }

      it 'return true' do
        expect(payment.pending?).to be false
        expect(payment.payment_method.enable_pre_auth?).to be true
        expect(subject.send(:can_cancel_pre_auth?)).to be true
      end
    end

    context 'pre-auth is disable and payment is not authroized' do
      let(:payment_method) { create(:payway_v2_gateway, enable_pre_auth: false) }
      let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order, state: :checkout, payment_method: payment_method) }

      it 'return false' do
        expect(payment.pending?).to be false
        expect(payment.payment_method.enable_pre_auth?).to be false
        expect(subject.send(:can_cancel_pre_auth?)).to be false
      end
    end
  end

  describe '#extract_completer_failure_reason_code' do
    context 'when some items are out of stock' do      
      before do
        allow_any_instance_of(Spree::LineItem).to receive(:sufficient_stock?).and_return(false)
      end

      it 'return reason code :some_line_items_are_out_of_stock' do
        completer = Spree::Checkout::Complete.new.call(order: order)
        expect(subject.send(:extract_completer_failure_reason_code, completer.error)).to eq :some_line_items_are_out_of_stock
      end
    end

    context 'when some items are discontinued' do      
      before do
        allow_any_instance_of(Spree::Variant).to receive(:discontinued?).and_return(true)
      end

      it 'return reason code :some_line_items_are_out_of_stock' do
        completer = Spree::Checkout::Complete.new.call(order: order)
        expect(subject.send(:extract_completer_failure_reason_code, completer.error)).to eq :some_variants_are_discontinued
      end
    end

    context 'when error message is neither of above cases' do
      it 'return reason code :some_line_items_are_out_of_stock' do
        expect(subject.send(:extract_completer_failure_reason_code, { :base => nil })).to eq :unable_to_complete_order
        expect(subject.send(:extract_completer_failure_reason_code, '')).to eq :unable_to_complete_order
        expect(subject.send(:extract_completer_failure_reason_code, {})).to eq :unable_to_complete_order
        expect(subject.send(:extract_completer_failure_reason_code, nil)).to eq :unable_to_complete_order
      end
    end
  end
end