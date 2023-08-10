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

  describe "#continue_success_url" do
    it "return continue_success_url with tran_id, app_checkout, order_number, ot (order_token)" do
      ENV['PAYWAY_CONTINUE_SUCCESS_CALLBACK_URL'] = "https://contigo.asia/webhook/payways/v2_continue"

      payment = create(:payway_payment)
      subject = described_class.new(payment)

      allow(payment).to receive(:number).and_return "PF2IM21Q"
      allow(payment.order).to receive(:number).and_return "R226226575"

      expect(subject.continue_success_url).to eq 'https://contigo.asia/webhook/payways/v2_continue?app_checkout=no&order_number=R226226575&tran_id=PF2IM21Q'
    end
  end

  describe "#view_type" do
    it "return view_type: hosted_view for app checkout" do
      payment = create(:payway_payment)
      subject = described_class.new(payment, { app_checkout: true })

      expect(subject.view_type).to eq 'hosted_view'
    end

    it "return view_type: nil when not app checkout" do
      payment = create(:payway_payment)
      subject = described_class.new(payment)

      expect(subject.view_type).to eq nil
    end
  end
end
