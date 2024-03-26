require 'spec_helper'

RSpec.describe Vpago::PaymentRedirectHandler do
  let(:gateway) { create(:payway_gateway, auto_capture: true) }
  let(:payment_source) { create(:payway_payment_source, payment_method: gateway) }
  let(:payway_payment) { create(:payway_payment, payment_method: gateway, source: payment_source) }
  let(:acleda_payment) { create(:acleda_payment) }

  let(:general_payment) { create(:payment) }

  before do
    payway_payment.payment_method.preferences[:api_key] = 'API_KEY'
  end

  describe '.validate_payment' do
    context "when it's not payway gateway" do
      it 'raise error' do
        expect {
          Vpago::PaymentRedirectHandler.new(payment: general_payment).validate_payment
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when it's gateway payway" do
      it 'return true' do
        expect(Vpago::PaymentRedirectHandler.new(payment: payway_payment).validate_payment).to eq true
      end
    end
  end

  describe '.check_and_process_payment' do
    context "when payment option is cards" do
      it 'process payway card' do
        payway_payment.payment_method.preferences[:payment_option] = 'cards'
        handler = Vpago::PaymentRedirectHandler.new(payment: payway_payment)

        expect(payway_payment).to receive(:process!)
        expect(handler).to receive(:process_payway_card)

        handler.check_and_process_payment
      end
    end

    context "when payment options is abapay" do
      it 'process abapay deeplink' do
        payway_payment.payment_method.preferences[:payment_option] = 'abapay'
        handler = Vpago::PaymentRedirectHandler.new(payment: payway_payment)

        expect(payway_payment).to receive(:process!)
        expect(handler).to receive(:process_abapay_deeplink)

        handler.check_and_process_payment
      end
    end

    context "when payment options is acleda" do
      it 'processes payment & calls process_acleda_gateway' do
        handler = Vpago::PaymentRedirectHandler.new(payment: acleda_payment)

        expect(acleda_payment).to receive(:process!)
        expect(handler).to receive(:process_acleda_gateway)

        handler.check_and_process_payment
      end
    end
  end
end
