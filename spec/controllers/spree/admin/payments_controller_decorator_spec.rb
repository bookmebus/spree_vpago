require 'spec_helper'

# Unit-level coverage for the reprocess reset introduced by
# Spree::Admin::PaymentsControllerDecorator#fire. We exercise the private
# guard directly to avoid coupling to admin authentication infrastructure,
# while still verifying the important behaviour: which payments get reset
# back to `checkout` before the core `fire` re-runs the gateway.
RSpec.describe Spree::Admin::PaymentsController do
  let(:controller) { described_class.new }
  let(:order) { create(:order_with_line_items, state: :payment) }
  let(:payment) { create(:payway_v2_payment, order: order) }

  def stub_fire_request(event:)
    controller.instance_variable_set(:@payment, payment)
    allow(controller).to receive(:params).and_return(
      ActionController::Parameters.new(e: event)
    )
  end

  describe '#reset_stuck_payment_for_reprocess!' do
    context 'when firing process on a vpago payment' do
      before { stub_fire_request(event: 'process') }

      %w[processing void invalid failed].each do |stuck_state|
        it "resets a #{stuck_state} payment back to checkout" do
          payment.update!(state: stuck_state)

          expect {
            controller.send(:reset_stuck_payment_for_reprocess!)
          }.to change { payment.reload.state }.from(stuck_state).to('checkout')
        end
      end

      it 'leaves a checkout payment untouched' do
        payment.update!(state: 'checkout')

        expect {
          controller.send(:reset_stuck_payment_for_reprocess!)
        }.not_to change { payment.reload.state }
      end

      it 'leaves a pending payment untouched' do
        payment.update!(state: 'pending')

        expect {
          controller.send(:reset_stuck_payment_for_reprocess!)
        }.not_to change { payment.reload.state }
      end
    end

    context 'when firing a non-process event (e.g. void) on a stuck payment' do
      before { stub_fire_request(event: 'void') }

      it 'does not reset the payment' do
        payment.update!(state: 'processing')

        expect {
          controller.send(:reset_stuck_payment_for_reprocess!)
        }.not_to change { payment.reload.state }
      end
    end

    context 'when the payment is not a vpago payment' do
      let(:payment) { create(:payment, order: order) }

      before { stub_fire_request(event: 'process') }

      it 'does not reset the payment' do
        payment.update!(state: 'failed')

        expect {
          controller.send(:reset_stuck_payment_for_reprocess!)
        }.not_to change { payment.reload.state }
      end
    end
  end
end
