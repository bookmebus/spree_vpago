require 'spec_helper'

RSpec.describe Spree::Product, type: :model do
  describe "associations" do
    it { should have_many(:payout_profile_products).class_name('Spree::PayoutProfileProduct').inverse_of(:product) }
    it { should have_many(:payout_profiles).class_name('Spree::PayoutProfile').through(:payout_profile_products) }
  end
end