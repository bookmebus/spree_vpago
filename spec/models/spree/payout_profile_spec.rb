require 'spec_helper'

RSpec.describe Spree::PayoutProfile, type: :model do
  describe "acts_as_paranoid" do
    it { is_expected.to act_as_paranoid }
  end

  describe "validations" do
    it { should validate_presence_of(:type) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:bank_account_number) }
    it { should validate_uniqueness_of(:bank_account_number).scoped_to([:type, :vendor_id]) }
  end

  describe "associations" do
    it { should have_many(:payouts).class_name('Spree::Payout').inverse_of(:payout_profile) }
    it { should have_many(:payout_profile_products).class_name('Spree::PayoutProfileProduct').inverse_of(:payout_profile) }
    it { should have_many(:products).class_name('Spree::Product').through(:payout_profile_products) }
    it { should belong_to(:vendor).class_name('Spree::Vendor').optional(true).inverse_of(:payout_profiles) }
  end

  describe "scopes" do
    describe ".payway" do
      it "returns only payout profiles of type 'Spree::PayoutProfiles::PaywayV2'" do
        payway_profile = create(:payway_payout_profile, bank_account_number: '12345678')
        create(:payout_profile, bank_account_number: '87654321', type: 'ACLEDA')

        expect(Spree::PayoutProfile.payway).to eq([payway_profile])
      end
    end
  end

  describe "callbacks" do
    describe '#clear_default_cache' do
      let(:default_payway_profile) { create(:payway_payout_profile, default: true, bank_account_number: '12345678') }
      let(:not_default_payway_profile) { create(:payway_payout_profile, bank_account_number: '87654321') }

      it 'call clear_default_cache on update & payout profile is default' do
        expect(default_payway_profile).to receive(:clear_default_cache).once.and_call_original
        expect(not_default_payway_profile).to_not receive(:clear_default_cache)

        default_payway_profile.update!(name: 'New name')
        not_default_payway_profile.update!(name: 'New name')
      end
    end

    describe "#ensure_default_exists_and_clear_vendor" do
      context "when setting a payout profile as default" do
        it "ensures only one payout profile of the same type is set as default" do
          create(:payway_payout_profile, default: true, bank_account_number: '12345678')
          payout_profile = create(:payway_payout_profile, default: true, bank_account_number: '87654321')

          expect(Spree::PayoutProfile.where(default: true, type: payout_profile.class.name).count).to eq(1)
          expect(payout_profile.vendor_id).to be_nil
        end
      end

      context "when no default payout profile of the same type exists" do
        it "sets the current payout profile of the same type as default" do
          payout_profile = create(:payway_payout_profile)

          expect(payout_profile.default).to eq(true)
          expect(payout_profile.vendor_id).to be_nil
        end
      end
    end

    describe "#confirm_destroyable" do
      let!(:payout_profile) { create(:payway_payout_profile) }

      context "when other profiles exist" do
        it "does not allow to destroy the only profile" do
          payout_profile.destroy

          expect(Spree::PayoutProfile.count).to eq 1
        end
      end
    end
  end

  describe "#verified?" do
    it "returns true if verified_at is present" do
      payout_profile = create(:payway_payout_profile, verified_at: Time.current)
      expect(payout_profile.verified?).to eq(true)
    end

    it "returns false if verified_at is nil" do
      payout_profile = create(:payway_payout_profile, verified_at: nil)
      expect(payout_profile.verified?).to eq(false)
    end
  end

  describe "#verify!" do
    it "updates verified_at and response_data" do
      payout_profile = create(:payway_payout_profile)
      response_data = { "verification_status" => "success" }
      payout_profile.verify!(response_data)
      payout_profile.reload

      expect(payout_profile.verified_at).to be_present
      expect(payout_profile.response_data).to eq(response_data)
    end
  end

  describe "#reset_verification!" do
    it "resets verified_at to nil" do
      payout_profile = create(:payway_payout_profile, verified_at: Time.current)
      payout_profile.reset_verification!
      payout_profile.reload

      expect(payout_profile.verified_at).to be_nil
    end
  end

  describe "#can_be_deleted?" do
    it "returns true if there are other payout profiles of the same type" do
      create(:payway_payout_profile, bank_account_number: '12345678')
      payout_profile = create(:payway_payout_profile, bank_account_number: '87654321')

      expect(payout_profile.can_be_deleted?).to eq(true)
      expect(payout_profile.can_be_deleted?).to eq(true)
    end

    it "returns false if it's the only payout profile of the same type" do
      payout_profile = create(:payway_payout_profile)

      expect(payout_profile.can_be_deleted?).to eq(false)
    end
  end
end
