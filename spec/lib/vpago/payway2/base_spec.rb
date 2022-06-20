require 'spec_helper'

RSpec.describe Vpago::PaywayV2::Base do

  describe "#first_name" do
    it "return its first_name if there is no space surrounding it" do
      bill_address = create(:bill_address, first_name: 'Joe', last_name: 'Ann')
      order = create(:order, billing_address: bill_address)
      payment = create(:payment, order: order) 

      subject = described_class.new(payment, {})
      expect(subject.first_name).to eq 'Joe'

    end

    it 'trim the space if there are spaces surrounding the first_name' do
      bill_address = create(:bill_address, first_name: ' Joe with ', last_name: 'Ann')
      order = create(:order, billing_address: bill_address)
      payment = create(:payment, order: order) 

      subject = described_class.new(payment, {})
      expect(subject.first_name).to eq 'Joe with'
    end
  end

   describe "#last_name" do
    it "return its last_name if there is no spaces surrounding the last_name" do
      bill_address = create(:bill_address, first_name: 'Joe', last_name: 'Ann')
      order = create(:order, billing_address: bill_address)
      payment = create(:payment, order: order) 

      subject = described_class.new(payment, {})
      expect(subject.last_name).to eq 'Ann'

    end

    it 'trim the space if there are spaces surrounding the last_name' do
      bill_address = create(:bill_address, first_name: ' Joe with ', last_name: ' Awesome Ann ')
      order = create(:order, billing_address: bill_address)
      payment = create(:payment, order: order) 

      subject = described_class.new(payment, {})
      expect(subject.last_name).to eq 'Awesome Ann'
    end
  end
end
