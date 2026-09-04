require 'spec_helper'

RSpec.describe Spree::PaymentMethod, type: :model do
  describe '#enable_payout?' do
    it 'return false when not type payway v2' do
      payment_method = create(:acleda_payment_method)

      expect(payment_method.enable_payout?).to be false
    end

    it 'return false when default payout is not present' do
      payment_method = create(:payway_v2_gateway)

      expect(payment_method.type_payway_v2?).to be true
      expect(payment_method.default_payout_profile).to eq nil

      expect(payment_method.enable_payout?).to be false
    end

    it 'return false when default payout is not receivable?' do
      payment_method = create(:payway_v2_gateway)
      default_payout_profile = create(:payway_payout_profile, active: true, bank_account_number: '333', default: true, verified_at: nil)

      expect(payment_method.type_payway_v2?).to be true
      expect(payment_method.default_payout_profile).to eq default_payout_profile
      expect(payment_method.default_payout_profile.receivable?).to be false

      expect(payment_method.enable_payout?).to be false
    end

    it 'return true when is payway v2 & receiveable' do
      payment_method = create(:payway_v2_gateway)
      default_payout_profile = create(:payway_payout_profile, active: true, bank_account_number: '333', default: true, verified_at: Date.current)

      expect(payment_method.type_payway_v2?).to be true
      expect(payment_method.default_payout_profile).to eq default_payout_profile
      expect(payment_method.default_payout_profile.receivable?).to be true

      expect(payment_method.enable_payout?).to be true
    end
  end
end
