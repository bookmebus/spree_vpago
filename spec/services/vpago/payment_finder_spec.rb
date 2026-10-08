require 'spec_helper'

RSpec.describe Vpago::PaymentFinder do
  let(:order) { create(:order, number: 'R131576461') }
  let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order) }

  describe '#find_and_verify!' do
    context 'when all params is valid' do
      let(:order_jwt_token) { Vpago::PaymentUrlConstructor.new(payment).send(:order_jwt_token) }
      let(:params_hash) { { order_number: order.number, payment_number: payment.number, order_jwt_token: order_jwt_token } }

      subject { described_class.new(params_hash) }

      it 'return back correct payment' do
        expect(subject.find_and_verify!).to eq payment
      end
    end

    context 'when order number or payment number is invalid' do
      let(:order_jwt_token) { Vpago::PaymentUrlConstructor.new(payment).send(:order_jwt_token) }
      let(:params_hash) { { order_number: 'INVALID', payment_number: payment.number, order_jwt_token: order_jwt_token } }

      subject { described_class.new(params_hash) }

      it 'raise record not found' do
        expect { subject.find_and_verify! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when jwt is invalid' do
      let(:order_jwt_token) { Vpago::PaymentUrlConstructor.new(payment).send(:order_jwt_token) }
      let(:params_hash) { { order_number: order.number, payment_number: payment.number, order_jwt_token: 'invalid-jwt' } }

      subject { described_class.new(params_hash) }

      it 'raise standard error' do
        expect { subject.find_and_verify! }.to raise_error(StandardError)
      end
    end

    context 'with a Wing Mini App webhook' do
      let(:wing_payment) do
        create(:wing_mini_app_payment, number: 'PJ0MYD2Y', amount: 1.0,
                                        order: create(:order, number: 'R131576461', currency: 'USD'))
      end

      let(:wing_app_id) { 'WG_APPID_0001' }
      let(:wing_secret_api_key) { 'super-secret-key' }

      def wing_params(debit_amount:)
        fields = {
          'orderRef' => wing_payment.number,
          'debitAmount' => debit_amount,
          'debitCcy' => 'USD',
          'transactionId' => '0002367253451856',
          'transactionDate' => '2026-09-09 11:47'
        }
        plaintext = "#{wing_app_id}#{Vpago::WingMiniApp::WebhookVerifier::FIELDS.map { |f| fields[f].to_s }.join}#{wing_secret_api_key}"
        fields.merge('secretKey' => Digest::SHA256.hexdigest(plaintext.upcase).upcase).with_indifferent_access
      end

      before { stub_wing_mini_app_credentials(app_id: wing_app_id, secret_api_key: wing_secret_api_key) }

      # Regression: Wing's own spec says debitAmount is always 2-decimal ("1.00"),
      # but real payloads have sent "1" (no decimals) — this must still verify.
      it 'accepts a settlement whose debitAmount lacks decimals' do
        subject = described_class.new(wing_params(debit_amount: '1'))

        expect(subject.find_and_verify!).to eq wing_payment
      end

      it 'accepts a settlement whose debitAmount has decimals' do
        subject = described_class.new(wing_params(debit_amount: '1.00'))

        expect(subject.find_and_verify!).to eq wing_payment
      end

      it 'rejects a settlement for the wrong amount' do
        subject = described_class.new(wing_params(debit_amount: '999.00'))

        expect { subject.find_and_verify! }.to raise_error(/verification failed/)
      end
    end
  end

  describe '#find_and_verify' do
    context 'when params is invalid' do
      let(:order_jwt_token) { Vpago::PaymentUrlConstructor.new(payment).send(:order_jwt_token) }
      let(:params_hash) { { order_number: order.number, payment_number: payment.number, order_jwt_token: 'invalid-jwt' } }

      subject { described_class.new(params_hash) }

      it 'rescue the errors and return payment nil' do
        expect { subject.find_and_verify! }.to raise_error(StandardError)
        expect(subject.find_and_verify).to eq nil
      end
    end
  end
end
