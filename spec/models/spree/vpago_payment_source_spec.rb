require 'spec_helper'

RSpec.describe Spree::VpagoPaymentSource, type: :model do
  let(:gateway) { create(:payway_gateway, auto_capture: true) }
  let(:payment_source) { create(:payway_payment_source, payment_method: gateway) }
  
  # describe 'validates presence of updated_reason for update' do
  #   it 'does not require for new record' do
  #     source = build(:payway_payment_source) 
  #     expect(source.valid?).to eq true
  #   end

  #   it 'requires to be presence when it is a new record' do
  #     source = create(:payway_payment_source)
  #     source.payment_status = 'success'
  #     source.updated_reason = nil

  #     expect(source.valid?).to eq false
  #     expect(source.errors[:updated_reason].to_a).to eq ["can't be blank"]
  #   end

  # end

end
