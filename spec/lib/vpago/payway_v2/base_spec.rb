require 'spec_helper'

RSpec.describe Vpago::PaywayV2::Base do
  let!(:default_payout_profile) { create(:payway_payout_profile, active: true, bank_account_number: '333', default: true, verified_at: DateTime.current)}

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

  describe '#payout' do
    let(:payment) { create(:payway_payment) }
    subject { described_class.new(payment) }

    context 'when there are payouts' do
      let(:payouts) { [{ acc: '123456789', amt: '100.00' }] }

      it 'returns encoded payouts JSON' do
        allow_any_instance_of(Vpago::PaywayV2::PayoutsParamsConstructor).to receive(:call).and_return(payouts)

        encoded_payouts = Base64.strict_encode64(payouts.to_json)

        expect(subject.payout).to eq(encoded_payouts)
      end
    end

    context 'when there are no payouts' do
      let(:empty_payouts) { [] }

      it 'returns nil' do
        allow_any_instance_of(Vpago::PaywayV2::PayoutsParamsConstructor).to receive(:call).and_return(empty_payouts)

        expect(subject.payout).to be_nil
      end
    end
  end

  describe '#hash_data' do
    let(:payment_method) { create(:payway_v2_gateway) }
    let(:payment) { create(:payway_payment, payment_method: payment_method) }

    subject { described_class.new(payment) }

    let(:req_time) { '20240516113705' }
    let(:merchant_id) { 'contingo' }
    let(:transaction_id) { 'PFSG7VBE' }
    let(:amount) { '29.99' }
    let(:first_name) { 'John' }
    let(:last_name) { 'Doe' }
    let(:email) { 'john@example.com' }
    let(:phone) { '123456789' }
    let(:payment_option) { 'abapay' }
    let(:return_url) { 'https://contigo.asia/webhook/payways/return' }
    let(:continue_success_url) { 'https://contigo.asia/webhook/payways/v2_continue?app_checkout=no&order_number=R127975733&tran_id=PFSG7VBE' }
    let(:return_params) { "{\"tran_id\":\"PFSG7VBE\"}" }

    before do
      allow(subject).to receive(:req_time).and_return(req_time)
      allow(subject).to receive(:merchant_id).and_return(merchant_id)
      allow(subject).to receive(:transaction_id).and_return(transaction_id)
      allow(subject).to receive(:amount).and_return(amount)
      allow(subject).to receive(:first_name).and_return(first_name)
      allow(subject).to receive(:last_name).and_return(last_name)
      allow(subject).to receive(:email).and_return(email)
      allow(subject).to receive(:phone).and_return(phone)
      allow(subject).to receive(:payment_option).and_return(payment_option)
      allow(subject).to receive(:return_url).and_return(return_url)
      allow(subject).to receive(:continue_success_url).and_return(continue_success_url)
      allow(subject).to receive(:return_params).and_return(return_params)
    end

    context 'when payout is nil' do      
      it 'constuct without payout' do
        allow(subject).to receive(:payout).and_return(nil)

        expect(subject.hash_data).to eq([
          req_time,
          merchant_id,
          transaction_id,
          amount,
          first_name,
          last_name,
          email,
          phone,
          payment_option,
          return_url,
          continue_success_url,
          return_params
        ].join(""))
      end
    end

    context 'when payout is present?' do
      it 'constuct with payout' do
        payout = 'W3siYWNjIjoiMTIzNDU2Nzg5IiwiYW10IjoiMTAwLjAwIn1d'

        allow(subject).to receive(:payout).and_return(payout)

        expect(subject.hash_data).to eq([
          req_time,
          merchant_id,
          transaction_id,
          amount,
          first_name,
          last_name,
          email,
          phone,
          payment_option,
          return_url,
          continue_success_url,
          return_params,
          payout
        ].join(""))
      end
    end
  end
end
