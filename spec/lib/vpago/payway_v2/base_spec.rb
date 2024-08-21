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

      expect(subject.continue_success_url).to eq  'https://contigo.asia/webhook/payways/v2_continue?app_checkout=no&order_channel=spree&order_number=R226226575&tran_id=PF2IM21Q'
    end
  end

  describe "#return_deeplink_url" do
    subject { described_class.new(payment) }

    context 'when continue_callback_url is not present' do
      let(:method) { create(:payway_v2_gateway, preferred_deeplink_scheme: 'bookmeplus') }
      let(:payment) { create(:payway_v2_payment, payment_method: method) }

      it "return nil (because deeplink url base on continue_url)" do
        ENV['PAYWAY_CONTINUE_SUCCESS_CALLBACK_URL'] = nil

        expect(subject.continue_success_url).to eq nil
        expect(subject.return_deeplink_url).to eq nil
      end
    end

    context 'when preferred_deeplink_scheme is not present' do
      let(:method) { create(:payway_v2_gateway, preferred_deeplink_scheme: nil) }
      let(:payment) { create(:payway_v2_payment, payment_method: method) }

      it "return nil" do
        ENV['PAYWAY_CONTINUE_SUCCESS_CALLBACK_URL'] = "https://contigo.asia/webhook/payways/v2_continue"

        expect(subject.return_deeplink_url).to eq nil
      end
    end

    context 'when continue_callback_url & preferred_deeplink_scheme is present' do
      let(:method) { create(:payway_v2_gateway, preferred_deeplink_scheme: 'bookmeplus') }
      let(:payment) { create(:payway_v2_payment, payment_method: method) }

      it "return return_deeplink url" do
        ENV['PAYWAY_CONTINUE_SUCCESS_CALLBACK_URL'] = "https://contigo.asia/webhook/payways/v2_continue"

        allow(payment).to receive(:number).and_return "PF2IM21Q"
        allow(payment.order).to receive(:number).and_return "R226226575"
  
        expect(subject.return_deeplink_url).to eq 'bookmeplus://contigo.asia/webhook/payways/v2_continue?app_checkout=no&order_channel=spree&order_number=R226226575&tran_id=PF2IM21Q'
      end
    end
  end

  describe "#subject.return_deeplink" do
    context 'when return_deeplink_url is not present?' do
      let(:method) { create(:payway_v2_gateway) }
      let(:payment) { create(:payway_v2_payment, payment_method: method) }

      subject { described_class.new(payment) }

      it 'return nil' do
        expect(subject.return_deeplink_url).to eq nil
        expect(subject.return_deeplink).to eq nil
      end
    end

    context 'when return_deeplink_url is present?' do
      let(:payment) { create(:payway_v2_payment) }

      subject { described_class.new(payment) }

      it 'return encoded base 64 of android / ios deeplink' do
        allow(subject).to receive(:return_deeplink_url).and_return 'bookmeplus://contigo.asia/webhook/payways/v2_continue?app_checkout=no&order_channel=spree&order_number=R226226575&tran_id=PF2IM21Q'

        expect(subject.return_deeplink).to eq Base64.strict_encode64({ android_scheme: subject.return_deeplink_url, ios_scheme: subject.return_deeplink_url }.to_json)
        expect(subject.return_deeplink).to eq "eyJhbmRyb2lkX3NjaGVtZSI6ImJvb2ttZXBsdXM6Ly9jb250aWdvLmFzaWEvd2ViaG9vay9wYXl3YXlzL3YyX2NvbnRpbnVlP2FwcF9jaGVja291dD1ub1x1MDAyNm9yZGVyX2NoYW5uZWw9c3ByZWVcdTAwMjZvcmRlcl9udW1iZXI9UjIyNjIyNjU3NVx1MDAyNnRyYW5faWQ9UEYySU0yMVEiLCJpb3Nfc2NoZW1lIjoiYm9va21lcGx1czovL2NvbnRpZ28uYXNpYS93ZWJob29rL3BheXdheXMvdjJfY29udGludWU/YXBwX2NoZWNrb3V0PW5vXHUwMDI2b3JkZXJfY2hhbm5lbD1zcHJlZVx1MDAyNm9yZGVyX251bWJlcj1SMjI2MjI2NTc1XHUwMDI2dHJhbl9pZD1QRjJJTTIxUSJ9"
      end
    end
  end
  # described_class '#return_deeplink' do
  #   subject { described_class.new(payment) }

  #   context 'when return_deeplink_url is present?' do
  #     let(:method) { create(:payway_v2_gateway, preferred_deeplink_scheme: 'bookmeplus') }
  #     let(:payment) { create(:payway_v2_payment, payment_method: method) }

  #     it 'encode deeplink for ios & android in base 64' do
  #       allow(subject).to receive(:return_deeplink_url).and_return "bookmeplus://contigo.asia/webhook/payways/v2_continue"

  #       expect(subject.return_deeplink).to eq ""
  #     end
  #   end
  # end
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

  describe '#payment_option' do
    context 'when payment_option is abapay_khqr_deeplink' do
      let(:payment_method) { create(:payway_v2_gateway, preferred_payment_option: 'abapay_khqr_deeplink') }
      let(:payment) { create(:payway_payment, payment_method: payment_method) }

      context 'when is not app checkout' do
        subject { described_class.new(payment, { app_checkout: false }) }

        it 'return payment_option = :abapay_khqr instead of :abapay_khqr_deeplink' do
          expect(subject.payment_option).to eq 'abapay_khqr'
        end
      end

      context 'when is app checkout' do
        subject { described_class.new(payment, { app_checkout: true }) }

        it 'return payment_option = :abapay_khqr_deeplink' do
          expect(subject.payment_option).to eq 'abapay_khqr_deeplink'
        end
      end
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
    let(:return_deeplink) { 'eyJhbmRyb2lkX3NjaGVtZSI6ImJvb2ttZXBsdXM6Ly9jb250aWdvLmFzaWEvd2ViaG9vay9wYXl3YXlzL3YyX2NvbnRpbnVlP2FwcF9jaGVja291dD1ub1x1MDAyNm9yZGVyX2NoYW5uZWw9c3ByZWVcdTAwMjZvcmRlcl9udW1iZXI9UjIyNjIyNjU3NVx1MDAyNnRyYW5faWQ9UEYySU0yMVEiLCJpb3Nfc2NoZW1lIjoiYm9va21lcGx1czovL2NvbnRpZ28uYXNpYS93ZWJob29rL3BheXdheXMvdjJfY29udGludWU/YXBwX2NoZWNrb3V0PW5vXHUwMDI2b3JkZXJfY2hhbm5lbD1zcHJlZVx1MDAyNm9yZGVyX251bWJlcj1SMjI2MjI2NTc1XHUwMDI2dHJhbl9pZD1QRjJJTTIxUSJ9' }
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
      allow(subject).to receive(:return_deeplink).and_return(return_deeplink)
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
          return_deeplink,
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
          return_deeplink,
          return_params,
          payout
        ].join(""))
      end
    end
  end
end
