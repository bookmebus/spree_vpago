require 'spec_helper'

RSpec.describe Vpago::Payments::FindOrCreate do
  include ActiveJob::TestHelper

  # This gem's ActiveJob test adapter isn't cleared between examples by any global hook, so
  # enqueued-job assertions here must not rely on the queue being empty at the start of the
  # example -- clear it explicitly rather than risk leakage from an earlier example in the run.
  before { clear_enqueued_jobs }

  # Simulates the client having already called checkout/add_store_credit before create_payment
  # (plans/2026-09-08-vpago-order-processing-refactor/plan.md) -- builds the payment directly
  # rather than going through SpreeCmCommissioner::Checkout::AddStoreCreditPayments, since that
  # service isn't loaded in this gem's own dummy app.
  def apply_store_credit!(order, amount:)
    method = order.payments.map(&:payment_method).find { |pm| pm.is_a?(Spree::PaymentMethod::StoreCredit) } ||
             create(:store_credit_payment_method, stores: [order.store])
    credit = create(:store_credit, user: order.user, amount: amount, store: order.store)
    order.payments.create!(payment_method: method, source: credit, amount: amount, state: :checkout)
  end

  describe '.call' do
    context 'when no valid payment exist' do
      let(:order) { create(:order) }
      let(:method) { create(:payway_v2_gateway) }
      let(:params) { { payment_method_id: method.id, source_attributes: { payment_option: 'abapay_khqr' } } }

      let(:existing_payment) { described_class.call(order: order, params: params).value[:order].payments.first }

      before do
        existing_payment.update(state: :failed)
      end

      it 'create new payment with source' do
        expect(order.payments.length).to eq 1

        result = described_class.call(order: order, params: params)

        expect(result.success?)
        expect(order.payments.length).to eq 2
        expect(order.payments[1].id).not_to eq existing_payment.id
        expect(order.payments[1].source.class).to eq method.payment_source_class
      end
    end

    context 'when the payment method is store credit' do
      let(:user) { create(:user) }
      let(:order) { create(:order, user: user, total: 25.00, currency: 'USD') }
      let(:method) { create(:store_credit_payment_method, stores: [order.store]) }
      let(:params) { { payment_method_id: method.id, source_attributes: { payment_option: 'storecredit' } } }

      # Fund the wallet so the store-credit method is actually available_for_order? and
      # find_payment_method resolves it -- otherwise the request fails one step earlier
      # (:payment_method_not_found), never reaching the guard under test here.
      before { create(:store_credit, user: user, amount: order.total + 10.00, store: order.store) }

      # Store credit is applied through checkout/add_store_credit now, never through
      # create_payment -- Spree::PaymentMethod::StoreCredit's source_class has neither a
      # payment_method_id column nor the fields a blank .new(...) would need to save, so this
      # must fail clearly rather than attempt to build a broken payment.
      it 'fails without creating any payment' do
        result = described_class.call(order: order, params: params)

        expect(result.success?).to be false
        expect(result.error.to_s).to eq 'store_credit_must_be_applied_via_add_store_credit'
        expect(order.reload.payments).to be_empty
      end
    end

    context 'when the payment method is CashOn (also no bank webhook)' do
      let(:order) { create(:order, total: 15.00, currency: 'USD') }
      let(:method) { Spree::PaymentMethod::CashOn.create!(name: 'Cash on Delivery', stores: [order.store]) }
      let(:params) { { payment_method_id: method.id, source_attributes: {} } }

      # Settlement is triggered by the client instead: the app always opens the vpago webview for
      # CashOn (its method_type isn't 'check', so it's not skipped like store credit is), and the
      # processing page's JS posts process_payment_url itself -- see
      # gems/spree_vpago/app/controllers/spree/vpago_payments_controller.rb#checkout.
      it 'does not enqueue PaymentProcessorJob -- the client-opened processing page triggers it instead' do
        expect {
          described_class.call(order: order, params: params)
        }.not_to have_enqueued_job(Vpago::PaymentProcessorJob)
      end
    end

    context 'when the payment method is a real gateway that supports check_transaction' do
      let(:order) { create(:order) }
      let(:method) { create(:payway_v2_gateway) }
      let(:params) { { payment_method_id: method.id, source_attributes: { payment_option: 'abapay_khqr' } } }

      it 'does not enqueue PaymentProcessorJob -- the bank webhook (#process_payment) triggers it instead' do
        expect {
          described_class.call(order: order, params: params)
        }.not_to have_enqueued_job(Vpago::PaymentProcessorJob)
      end
    end

    context 'when store credit was already applied (via checkout/add_store_credit) toward a CashOn remainder' do
      let(:user) { create(:user) }
      let(:order) { create(:order, user: user, state: :payment, total: 18.00, currency: 'USD') }
      let(:method) { Spree::PaymentMethod::CashOn.create!(name: 'Cash on Delivery', stores: [order.store]) }
      let(:params) { { payment_method_id: method.id, source_attributes: {} } }

      before { apply_store_credit!(order, amount: 10.00) }

      # No params needed at all -- Spree::Order#order_total_after_store_credit already sums the
      # store-credit payment created above (plans/2026-09-08-vpago-order-processing-refactor/plan.md).
      it 'sizes the remainder against order_total_after_store_credit' do
        result = described_class.call(order: order, params: params)

        expect(result.success?).to be true
        cash_on_payment = order.reload.payments.where(payment_method: method).first
        expect(cash_on_payment.amount).to eq 8.00
      end

      it 'does not enqueue PaymentProcessorJob for the CashOn remainder' do
        expect {
          described_class.call(order: order, params: params)
        }.not_to have_enqueued_job(Vpago::PaymentProcessorJob)
      end
    end

    context 'when store credit was already applied toward a webhook-confirmed gateway remainder' do
      let(:user) { create(:user) }
      let(:order) { create(:order, user: user, state: :payment, total: 18.00, currency: 'USD') }
      let(:method) { create(:payway_v2_gateway) }
      let(:params) { { payment_method_id: method.id, source_attributes: { payment_option: 'abapay_khqr' } } }

      before { apply_store_credit!(order, amount: 10.00) }

      it 'sizes the remainder gateway payment against order_total_after_store_credit' do
        result = described_class.call(order: order, params: params)

        expect(result.success?).to be true
        gateway_payment = order.reload.payments.where(payment_method: method).first
        expect(gateway_payment.amount).to eq 8.00
      end

      it 'does not enqueue any instant-settlement job -- the gateway webhook/return trigger settles it once it confirms' do
        described_class.call(order: order, params: params)

        expect(Vpago::PaymentProcessorJob).not_to have_been_enqueued
      end
    end

    context 'when the order is a prepaid top-up order' do
      # FindOrCreate has no prepaid-top-up-specific sizing guard -- circular top-up-with-store-credit
      # is guarded only by SpreeCmCommissioner::Checkout::AddStoreCreditPayments refusing to apply
      # store credit to a top-up order in the first place (not exercised here, since this gem's own
      # dummy app doesn't load that engine). A remainder payment on a top-up order sizes the same as
      # any other order: against order_total_after_store_credit.
      let(:user) { create(:user) }
      let(:order) { create(:order, user: user, total: 43.00, currency: 'USD') }

      before { allow(order).to receive(:prepaid_top_up_order?).and_return(true) }

      context 'paying with CashOn while the buyer already holds wallet balance' do
        let(:method) { Spree::PaymentMethod::CashOn.create!(name: 'Cash on Delivery', stores: [order.store]) }
        let(:params) { { payment_method_id: method.id, source_attributes: {} } }

        before { create(:store_credit, user: user, amount: 100.00, amount_used: 92.00, store: order.store) }

        it 'sizes the payment against order_total_after_store_credit, same as any other order' do
          result = described_class.call(order: order, params: params)

          expect(result.success?).to be true
          expect(order.reload.payments.where(payment_method: method).first!.amount).to eq 35.00
        end
      end
    end

    context 'when checkout payment exist' do
      let(:order) { create(:order) }
      let(:method) { create(:payway_v2_gateway) }
      let(:params) { { payment_method_id: method.id, source_attributes: { payment_option: 'abapay_khqr' } } }
      let(:existing_payment) { described_class.call(order: order, params: params).value[:order].payments.first }

      before do
        existing_payment.update(state: :checkout)
      end

      it 'return existing payment' do
        expect(order.payments.length).to eq 1

        result = described_class.call(order: order, params: params)

        expect(result.success?)
        expect(order.payments.length).to eq 1
        expect(order.payments[0].id).to eq existing_payment.id
        expect(order.payments[0].source.class).to eq method.payment_source_class
      end
    end
  end
end
