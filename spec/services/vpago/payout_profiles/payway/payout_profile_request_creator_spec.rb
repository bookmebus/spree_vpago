require 'spec_helper'

RSpec.describe Vpago::PayoutProfiles::Payway::PayoutProfileRequestCreator do
  describe '#call' do
    let(:profile) { create(:payway_payout_profile) } 
    subject { described_class.new(profile) }

    context 'when request successfully created' do
      before do
        expect(profile.verified?).to be false

        VCR.use_cassette('create_payway_payout_success_request') do
          subject.call
        end
      end

      it 'verify profile' do
        expect(profile.verified?).to be true
        expect(profile.response_data).to eq({
          "name" => "*********ount",
          "payee" => "002094060",
          "currency" => "USD",
          "type" => "ABA Account",
          "status" => 1,
          "created_at" => "2024-05-10 14:15:45"
        })
      end
    end

    context 'when request return payout account dublicated' do
      context 'when account is dublicated in bank but not in our database' do
        before do
          expect(profile.verified?).to be false    

          cassettes = [
            { name: 'create_payway_payout_account_dublicated_request' },
            { name: 'update_payway_payout_account_to_inactive_success' }
          ]

          VCR.use_cassettes(cassettes) do
            subject.call
          end
        end

        it 'verify profile' do
          expect(profile.verified?).to be true
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

      context 'when dublicate on both bank & our system' do
        let(:bank_account_number) { '002094060' }
        let(:dublicated_profile) { build(:payway_payout_profile, bank_account_number: bank_account_number) }

        # override
        let(:profile) { build(:payway_payout_profile, bank_account_number: bank_account_number) }

        before do
          profile.save
          dublicated_profile.save validate: false

          VCR.use_cassette('create_payway_payout_account_dublicated_request') do
            subject.call
          end
        end

        it 'mark verify false' do
          expect(profile.verified?).to be false
          expect(subject.error_messages).to eq [
            {
              "code" => "PTL148",
              "message" => "Payee already exists.",
              "tran_id" => "171532534657953"
            }
          ]
        end
      end
    end
  end
end
