require 'spec_helper'

RSpec.describe Spree::Payout, type: :model do
  subject { create(:payout) }

  describe "validations" do
    it { should validate_uniqueness_of(:payout_profile_id).scoped_to([:line_item_id, :payment_id]) }
  end

  describe "associations" do
    it { should belong_to(:payout_profile).class_name('Spree::PayoutProfile').optional(false).inverse_of(:payouts) }
    it { should belong_to(:line_item).class_name('Spree::LineItem').optional(true).inverse_of(:payouts) }
    it { should belong_to(:payment).class_name('Spree::Payment').optional(false).inverse_of(:payouts) }
  end
end
