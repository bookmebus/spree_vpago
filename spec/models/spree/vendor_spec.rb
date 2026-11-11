require 'spec_helper'

RSpec.describe Spree::Vendor, type: :model do
  it { should have_many(:payout_profiles).class_name('Spree::PayoutProfile').inverse_of(:vendor) }
end