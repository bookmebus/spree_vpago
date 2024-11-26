require 'spec_helper'

RSpec.describe Spree::Payment, type: :model do
  let!(:default_payout_profile) { create(:payway_payout_profile, active: true, bank_account_number: '333', default: true, verified_at: DateTime.current) }

  describe "associations" do
    it { should have_many(:payouts).class_name('Spree::Payout').inverse_of(:payment) }
  end

  describe 'callback: after_create' do
    context 'generating payouts' do
      context 'support payout true' do
        let(:generator) { Vpago::PayoutsGenerator.new(subject) }

        subject { build(:payway_v2_payment) }

        it 'calls Vpago::PayoutsGenerator' do
          expect(subject.support_payout?).to be true
          expect(Vpago::PayoutsGenerator).to receive(:new).with(subject).and_return(generator)
          expect(generator).to receive(:call).and_call_original   

          subject.save!
        end
      end

      context 'support payout false' do
        let(:generator) { Vpago::PayoutsGenerator.new(subject) }

        subject { build(:payway_payment) }

        it 'does not call Vpago::PayoutsGenerator' do
          expect(subject.support_payout?).to be false
          expect(Vpago::PayoutsGenerator).to_not receive(:new).with(subject)

          subject.save!
        end
      end
    end
  end

  describe '#process!' do
    context 'when auto capture true & payment receive manually' do
      let(:payment_method) { create(:check_payment_method, auto_capture: true) }
      subject { create(:check_payment, state: 'checkout', payment_method: payment_method) }
      
      it 'complete payment during process directly' do
        allow(subject).to receive(:payment_receive_manually?).and_return(true)
        expect(subject).to receive(:complete!).and_call_original

        subject.process!
  
        expect(subject.state).to eq 'completed'
      end
    end

    context 'when auto capture false but payment receive manually' do
      let(:payment_method) { create(:check_payment_method, auto_capture: false) }
      subject { create(:check_payment, state: 'checkout', payment_method: payment_method) }

      it 'does not complete the payment & just call super' do
        allow(subject).to receive(:payment_receive_manually?).and_return(true)
        expect(subject).not_to receive(:complete!)

        subject.process!
      end
    end

    context 'when auto capture true but not payment receive manually' do
      let(:payment_method) { create(:check_payment_method, auto_capture: true) }
      subject { create(:check_payment, state: 'checkout', payment_method: payment_method) }

      it 'does not complete the payment & just call super' do
        allow(subject).to receive(:payment_receive_manually?).and_return(false)
        expect(subject).not_to receive(:complete!)

        subject.process!
      end
    end
  end
end
