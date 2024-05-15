require 'spec_helper'

RSpec.describe Spree::LineItem, type: :model do
  it { should have_many(:payout_profiles).class_name('Spree::PayoutProfile').through(:product) }
end