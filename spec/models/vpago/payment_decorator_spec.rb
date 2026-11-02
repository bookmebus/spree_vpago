require 'spec_helper'

RSpec.describe Vpago::PaymentDecorator do
  let(:order) { create(:order_with_line_items) }
  let(:payment_method) { create(:payway_v2_gateway, enable_pre_auth: true, preferred_public_key: 'public-key') }
  let(:payment) { create(:payway_v2_payment, order: order, payment_method: payment_method, state: 'pending') }

  let(:failed_response) { ActiveMerchant::Billing::Response.new(false, 'Payway Gateway: Capture Failed', {}) }
  let(:success_response) { ActiveMerchant::Billing::Response.new(true, 'Payway Gateway: Captured', {}) }

  describe '#capture! for a pre-auth payment' do
    context 'when the gateway rejects the capture' do
      before { allow_any_instance_of(Spree::Gateway::PaywayV2).to receive(:capture).and_return(failed_response) }

      it 'raises so the job retries, and leaves the payment pending without a capture event' do
        expect { payment.capture! }.to raise_error(Spree::Core::GatewayError)

        payment.reload
        expect(payment.state).to eq 'pending'
        expect(payment.capture_events).to be_empty
        expect(payment.state_changes).to be_empty
      end

      it 'logs the gateway response' do
        expect { payment.capture! }.to raise_error(Spree::Core::GatewayError)

        expect(payment.log_entries.count).to eq 1
        expect(payment.log_entries.last.parsed_details.message).to eq 'Payway Gateway: Capture Failed'
      end

      it 'keeps capture available for the next attempt' do
        order.update_columns(state: 'complete', completed_at: Time.current)

        expect { payment.capture! }.to raise_error(Spree::Core::GatewayError)

        expect(payment.reload.actions).to include('capture')
      end
    end

    context 'when the gateway call times out' do
      before { allow_any_instance_of(Spree::Gateway::PaywayV2).to receive(:capture).and_raise(Faraday::TimeoutError) }

      it 'raises a connection GatewayError and leaves the payment pending' do
        expect { payment.capture! }.to raise_error(Spree::Core::GatewayError, Spree.t(:unable_to_connect_to_gateway))

        expect(payment.reload.state).to eq 'pending'
        expect(payment.capture_events).to be_empty
      end

      it 'logs the attempt, which Spree skips for connection errors' do
        expect { payment.capture! }.to raise_error(Spree::Core::GatewayError)

        expect(payment.log_entries.last.parsed_details.message).to start_with('Payway Gateway: Faraday::TimeoutError')
      end
    end

    context 'when the gateway captures' do
      before { allow_any_instance_of(Spree::Gateway::PaywayV2).to receive(:capture).and_return(success_response) }

      it 'completes the payment with exactly one capture event' do
        payment.capture!

        payment.reload
        expect(payment.state).to eq 'completed'
        expect(payment.capture_events.sum(:amount)).to eq payment.amount
        expect(payment.state_changes.pluck(:previous_state, :next_state)).to eq [%w[pending completed]]
      end

      it 'completes a payment left in processing by an earlier crash' do
        payment.update_columns(state: 'processing')

        payment.capture!

        expect(payment.reload.state).to eq 'completed'
      end
    end

    context 'when the payment is failed' do
      before { payment.update_columns(state: 'failed') }

      it 'refuses without calling the gateway' do
        expect_any_instance_of(Spree::Gateway::PaywayV2).not_to receive(:capture)

        expect { payment.capture! }.to raise_error(Spree::Core::GatewayError, /in state failed/)
        expect(payment.reload.state).to eq 'failed'
      end
    end
  end

  describe '#capture! for a payment without pre-auth' do
    let(:payment_method) { create(:payway_v2_gateway, enable_pre_auth: false) }

    before { allow_any_instance_of(Spree::Gateway::PaywayV2).to receive(:capture).and_return(failed_response) }

    it "keeps Spree's behaviour and marks the payment failed" do
      expect { payment.capture! }.to raise_error(Spree::Core::GatewayError)

      expect(payment.reload.state).to eq 'failed'
    end
  end

  describe '#awaiting_pre_auth_capture?' do
    it 'is true while a pre-auth payment is pending or processing' do
      expect(payment.awaiting_pre_auth_capture?).to be true

      payment.state = 'processing'
      expect(payment.awaiting_pre_auth_capture?).to be true
    end

    it 'is false once captured' do
      payment.state = 'completed'
      expect(payment.awaiting_pre_auth_capture?).to be false
    end

    it 'is false without pre-auth' do
      payment_method.update!(enable_pre_auth: false)
      expect(payment.reload.awaiting_pre_auth_capture?).to be false
    end
  end
end
