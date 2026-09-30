require 'spec_helper'

RSpec.describe Vpago::PayoutProfiles::Payway::PayoutProfileRequestUpdater do
  describe '#call' do
    context 'when request successfully update to active' do
      let(:profile) { create(:payway_payout_profile, active: true) } 
      subject { described_class.new(profile) }

      before do
        VCR.use_cassette('update_payway_payout_account_to_active_success') do
          subject.call
        end
      end

      it 'update profile to database' do
        expect(profile.active).to be true
        expect(profile.response_data).to eq({
          "name" => "*********ount",
          "payee" => "070486124",
          "currency" => "USD",
          "type" => "ABA Account",
          "status" => "1",
          "created_at" => "2024-05-10 11:20:03.000"
        })
      end
    end

    context 'when request successfully update to inative' do
      let(:profile) { create(:payway_payout_profile, active: false) } 
      subject { described_class.new(profile) }

      before do
        VCR.use_cassette('update_payway_payout_account_to_inactive_success') do
          subject.call
        end
      end

      it 'does not save the profile' do
        expect(profile.active).to be false
        expect(profile.response_data).to eq({
          "name" => "*********ount",
          "payee" => "070486124",
          "currency" => "USD",
          "type" => "ABA Account",
          "status" => "0",
          "created_at" => "2024-05-10 11:20:03.000"
        })
      end
    end
  end
end
