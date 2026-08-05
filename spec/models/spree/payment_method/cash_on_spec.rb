require 'spec_helper'

RSpec.describe Spree::PaymentMethod::CashOn, type: :model do
  let(:payment_method) { create(:cash_on_payment_method) }

  describe '#cancel' do
    it 'returns a successful billing response' do
      response = payment_method.cancel('response-code', nil)

      expect(response).to be_a ActiveMerchant::Billing::Response
      expect(response.success?).to be true
      expect(response.message).to eq 'Cash On: Payment has been canceled.'
    end

    # Spree::Payment#cancel! calls payment_method.cancel(response_code, payment).
    it 'accepts the response_code & payment arguments' do
      payment = create(:cash_on_payment, payment_method: payment_method)

      expect { payment_method.cancel(payment.response_code, payment) }.not_to raise_error
    end
  end

  describe 'canceling an order paid by cash' do
    let(:order) { create(:completed_order_with_totals) }
    let!(:payment) do
      create(:cash_on_payment, payment_method: payment_method, order: order, amount: order.total, state: 'completed')
    end

    it 'voids the payment & cancels the order' do
      expect { order.cancel! }.not_to raise_error

      expect(order.reload.state).to eq 'canceled'
      expect(payment.reload.state).to eq 'void'
    end
  end
end
