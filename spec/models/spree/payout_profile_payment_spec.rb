require 'spec_helper'

RSpec.describe Spree::PayoutProfilePayment, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:payout_profile).class_name('Spree::PayoutProfile').inverse_of(:payout_profile_payments) }
    it { is_expected.to belong_to(:payment).class_name('Spree::Payment').inverse_of(:payout_profile_payments) }
  end
end
