require 'spec_helper'

RSpec.describe Spree::Payment, type: :model do
  describe "associations" do
    it { should have_many(:payout_profile_payments).class_name('Spree::PayoutProfilePayment').inverse_of(:payment) }
  end
end
