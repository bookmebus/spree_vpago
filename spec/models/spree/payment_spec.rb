require 'spec_helper'

RSpec.describe Spree::Payment, type: :model do
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
end
