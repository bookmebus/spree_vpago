require 'spec_helper'

RSpec.describe Spree::Payment, type: :model do
  let!(:default_payout_profile) { create(:payway_payout_profile, active: true, bank_account_number: '333', default: true, verified_at: DateTime.current)}

  describe "associations" do
    it { should have_many(:payouts).class_name('Spree::Payout').inverse_of(:payment) }
  end

  describe 'callback: after_create' do
    context 'generating payouts' do
      context 'support payout true' do
        let(:generator) { Vpago::PayoutsGenerator.new(subject) }

        subject { build(:payway_v2_payment) }

        it 'calls Vpago::PayoutsGenerator' do
          expect(subject.payment_method.enable_payout?).to be true
          expect(Vpago::PayoutsGenerator).to receive(:new).with(subject).and_return(generator)
          expect(generator).to receive(:call).and_call_original   

          subject.save!
        end
      end

      context 'support payout false' do
        let(:generator) { Vpago::PayoutsGenerator.new(subject) }

        subject { build(:payway_payment) }

        it 'does not call Vpago::PayoutsGenerator' do
          expect(subject.payment_method.enable_payout?).to be false
          expect(Vpago::PayoutsGenerator).to_not receive(:new).with(subject)

          subject.save!
        end
      end
    end
  end

  describe '#process!' do
    let(:order) { create(:order_with_line_items, state: :payment) }
    let(:payment_method) { create(:payway_v2_gateway) }
    let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order, payment_method: payment_method) }

    context 'when payment is in processing state' do
      before do
        # Mock purchase! to simulate a payment attempt
        allow(payment).to receive(:purchase!)
      end

      it 'does not reset payment when already processing' do
        payment.update!(state: 'processing')
        expect(payment).to_not receive(:reset_for_retry!)

        payment.process!
      end

      it 'calls purchase! without reset' do
        payment.update!(state: 'processing')
        expect(payment).to receive(:purchase!).ordered
        
        payment.process!
      end
    end

    context 'when payment is in failed state' do
      before do
        # Mock purchase! to simulate a payment attempt
        allow(payment).to receive(:purchase!)
      end

      it 'resets payment for retry before processing' do
        payment.update!(state: 'failed')
        expect(payment).to receive(:reset_for_retry!).and_call_original
        
        payment.process!
        # State should be checkout after reset_for_retry!, then purchase! is called
        expect(payment.state).to eq('checkout')
      end

      it 'calls reset_for_retry! then purchase!' do
        payment.update!(state: 'failed')
        expect(payment).to receive(:reset_for_retry!).ordered.and_call_original
        expect(payment).to receive(:purchase!).ordered
        
        payment.process!
      end
    end

    context 'when faraday connection error raised during process' do
      it 'capture faraday error and rethow as gateway error (order only rescue gateway error)' do
        expect(payment).to receive(:gateway_error).and_call_original do |error|
          expect(error).to be_a(ActiveMerchant::ConnectionError)
          expect(error.triggering_exception).to be_a(Faraday::ConnectionFailed)
        end

        VCR.use_cassette("connection_error") do
          expect {
            payment.process!
          }.to raise_error(Spree::Core::GatewayError, Spree.t(:unable_to_connect_to_gateway))
        end
      end
    end
  end

  describe '#capture!' do
    let(:order) { create(:order_with_line_items, state: :payment) }
    let(:payment_method) { create(:payway_v2_gateway) }
    let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order, payment_method: payment_method) }

    context 'when payment is in processing state' do
      before do
        # Mock protect_from_connection_error to do nothing
        allow(payment).to receive(:protect_from_connection_error).and_return(nil)
      end

      it 'does not reset payment when already processing' do
        payment.update!(state: 'processing')
        expect(payment).to_not receive(:reset_for_retry!)

        payment.capture!

        expect(payment.reload.state).to eq('processing')
      end

      it 'calls capture without reset' do
        payment.update!(state: 'processing')
        expect(payment).to receive(:protect_from_connection_error).ordered

        payment.capture!

        # capture will start processing again.
        expect(payment.reload.state).to eq('processing')
      end
    end

    context 'when payment is in failed state' do
      before do
        # Mock protect_from_connection_error to do nothing
        allow(payment).to receive(:protect_from_connection_error).and_return(nil)
      end

      it 'resets payment for retry before capturing' do
        payment.update!(state: 'failed')
        expect(payment).to receive(:reset_for_retry!).and_call_original
        
        payment.capture!

        # capture will start processing again.
        expect(payment.reload.state).to eq('processing')
      end

      it 'calls reset_for_retry! then proceeds with capture' do
        payment.update!(state: 'failed')
        expect(payment).to receive(:reset_for_retry!).ordered.and_call_original
        expect(payment).to receive(:protect_from_connection_error).ordered
        
        payment.capture!
        
        # capture will start processing again.
        expect(payment.reload.state).to eq('processing')
      end
    end

    context 'when faraday connection error raised during capture' do
      it 'capture faraday error and rethow as gateway error (order only rescue gateway error)' do
        # Simulate the actual capture! flow by having protect_from_connection_error raise the error
        allow(payment).to receive(:protect_from_connection_error).and_call_original
        allow(payment.payment_method).to receive(:capture).and_raise(Faraday::ConnectionFailed.new('Connection failed'))
        
        expect(payment).to receive(:gateway_error).and_call_original do |error|
          expect(error).to be_a(ActiveMerchant::ConnectionError)
          expect(error.triggering_exception).to be_a(Faraday::ConnectionFailed)
        end

        expect {
          payment.capture!
        }.to raise_error(Spree::Core::GatewayError, Spree.t(:unable_to_connect_to_gateway))

        expect(payment.reload.state).to eq('failed')
      end
    end
  end

  describe '#reset_for_retry!' do
    let(:order) { create(:order_with_line_items, state: :payment) }
    let(:payment_method) { create(:payway_v2_gateway) }
    let(:payment) { create(:payway_v2_payment, order: order, payment_method: payment_method) }

    context 'when payment is in failed state' do
      it 'transitions payment from failed to checkout' do
        payment.update!(state: 'failed')
        
        expect {
          payment.reset_for_retry!
        }.to change { payment.state }.from('failed').to('checkout')
      end
    end

    context 'when payment is not in failed state' do
      it 'does not transition from processing state' do
        payment.update!(state: 'processing')
        
        expect {
          payment.reset_for_retry!
        }.to raise_error(StateMachines::InvalidTransition)
      end

      it 'does not transition from completed state' do
        payment.update!(state: 'completed')
        
        expect {
          payment.reset_for_retry!
        }.to raise_error(StateMachines::InvalidTransition)
      end

      it 'does not transition from checkout state' do
        payment.update!(state: 'checkout')
        
        expect {
          payment.reset_for_retry!
        }.to raise_error(StateMachines::InvalidTransition)
      end

      it 'does not transition from pending state' do
        payment.update!(state: 'pending')
        
        expect {
          payment.reset_for_retry!
        }.to raise_error(StateMachines::InvalidTransition)
      end
    end
  end

  describe '#protect_from_connection_error' do
    let(:order) { create(:order_with_line_items, state: :payment) }
    let(:payment_method) { create(:payway_v2_gateway) }
    let(:payment) { create(:payway_v2_payment, order: order, payment_method: payment_method) }

    context 'when ActiveMerchant::ConnectionError is raised' do
      it 'calls failure! and gateway_error' do
        # ActiveMerchant::ConnectionError requires message and response parameters
        error = ActiveMerchant::ConnectionError.new('Connection failed', nil)
        
        expect(payment).to receive(:failure!).ordered
        expect(payment).to receive(:gateway_error).with(error).ordered.and_call_original
        
        expect {
          payment.protect_from_connection_error do
            raise error
          end
        }.to raise_error(Spree::Core::GatewayError)
      end

      it 'transitions payment to failed state' do
        payment.update!(state: 'processing')
        # ActiveMerchant::ConnectionError requires message and response parameters
        error = ActiveMerchant::ConnectionError.new('Connection failed', nil)
        
        expect {
          payment.protect_from_connection_error do
            raise error
          end
        }.to raise_error(Spree::Core::GatewayError)
        
        expect(payment.reload.state).to eq('failed')
      end
    end

    context 'when Faraday::ConnectionFailed is raised' do
      it 'wraps error in ActiveMerchant::ConnectionError and calls failure! and gateway_error' do
        faraday_error = Faraday::ConnectionFailed.new('Network error')
        
        expect(payment).to receive(:failure!).ordered
        expect(payment).to receive(:gateway_error).ordered do |error|
          expect(error).to be_a(ActiveMerchant::ConnectionError)
          expect(error.message).to eq('Network error')
          expect(error.triggering_exception).to eq(faraday_error)
        end.and_call_original
        
        expect {
          payment.protect_from_connection_error do
            raise faraday_error
          end
        }.to raise_error(Spree::Core::GatewayError)
      end

      it 'transitions payment to failed state' do
        payment.update!(state: 'processing')
        faraday_error = Faraday::ConnectionFailed.new('Network error')
        
        expect {
          payment.protect_from_connection_error do
            raise faraday_error
          end
        }.to raise_error(Spree::Core::GatewayError)
        
        expect(payment.reload.state).to eq('failed')
      end
    end

    context 'when Faraday::TimeoutError is raised' do
      it 'wraps error in ActiveMerchant::ConnectionError and calls failure! and gateway_error' do
        timeout_error = Faraday::TimeoutError.new('Request timeout')
        
        expect(payment).to receive(:failure!).ordered
        expect(payment).to receive(:gateway_error).ordered do |error|
          expect(error).to be_a(ActiveMerchant::ConnectionError)
          expect(error.message).to eq('Request timeout')
          expect(error.triggering_exception).to eq(timeout_error)
        end.and_call_original
        
        expect {
          payment.protect_from_connection_error do
            raise timeout_error
          end
        }.to raise_error(Spree::Core::GatewayError)
      end

      it 'transitions payment to failed state' do
        payment.update!(state: 'processing')
        timeout_error = Faraday::TimeoutError.new('Request timeout')
        
        expect {
          payment.protect_from_connection_error do
            raise timeout_error
          end
        }.to raise_error(Spree::Core::GatewayError)
        
        expect(payment.reload.state).to eq('failed')
      end
    end

    context 'when no error is raised' do
      it 'executes the block successfully' do
        result = payment.protect_from_connection_error do
          'success'
        end
        
        expect(result).to eq('success')
      end

      it 'does not call failure! or gateway_error' do
        expect(payment).to_not receive(:failure!)
        expect(payment).to_not receive(:gateway_error)
        
        payment.protect_from_connection_error do
          'success'
        end
      end
    end

    context 'when other errors are raised' do
      it 'does not rescue the error' do
        expect {
          payment.protect_from_connection_error do
            raise StandardError, 'Other error'
          end
        }.to raise_error(StandardError, 'Other error')
      end
    end
  end
end
