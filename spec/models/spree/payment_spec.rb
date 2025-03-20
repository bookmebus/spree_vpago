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
    let(:payment_method) { create(:payway_v2_gateway, preferred_host: 'https://bad-url') }
    let(:payment) { create(:payway_v2_payment, number: 'PJ0MYD2Y', order: order, payment_method: payment_method) }

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
end
