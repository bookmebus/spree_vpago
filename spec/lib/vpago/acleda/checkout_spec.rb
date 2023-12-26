require 'spec_helper'

RSpec.describe Vpago::Acleda::Checkout do
  let(:order) { create(:order, number: 'R156303026')}

  describe '#create_session_request_body' do
    it 'return xpay request body with paymentCard' do
      acleda_method = create(:acleda_xpay_mpgs_payment_method, :xpay)
      payment = create(:acleda_payment, number: 'PXDMNSPA', payment_method: acleda_method, order: order, created_at: Date.new(2023, 01, 23))

      allow_any_instance_of(described_class).to receive(:start_connection)
      allow_any_instance_of(described_class).to receive(:update_payment_source)

      context = described_class.new(payment)

      expect(context.create_session_request_body).to eq(
        :loginId=>"remoteuser", 
        :password=>"12345678", 
        :merchantID=>"Fake-Ao01Lr/y10389Ww82q1Z7meWY=", 
        :signature=>"7c7504903", 
        :xpayTransaction=>{
          :txid=>"PXDMNSPA", 
          :invoiceid=>"R156303026", 
          :purchaseAmount=>"29.99", 
          :purchaseCurrency=>"USD", 
          :purchaseDate=>"23-01-2023", 
          :purchaseDesc=>"items", 
          :item=>"1", 
          :quantity=>"1", 
          :expiryTime=>10, 
          :otherUrl=>"https://example/webhook/acledas/return?app_checkout=0&order_number=R156303026", 
          :paymentCard=>1
        }
      )
    end

    it 'return khqr request body with operationType' do
      acleda_method = create(:acleda_khqr_payment_method)
      payment = create(:acleda_payment, number: 'PXDMNSPA', payment_method: acleda_method, order: order, created_at: Date.new(2023, 01, 23))

      allow_any_instance_of(described_class).to receive(:start_connection)
      allow_any_instance_of(described_class).to receive(:update_payment_source)

      context = described_class.new(payment)

      expect(context.create_session_request_body).to eq(
        :loginId=>"remoteuser",
        :password=>"12345678",
        :merchantID=>"Fake-Ao01Lr/y10389Ww82q1Z7meWY=",
        :signature=>"7c7504903",
        :xpayTransaction=>{
          :txid=>"PXDMNSPA",
          :invoiceid=>"R156303026",
          :purchaseAmount=>"29.99",
          :purchaseCurrency=>"USD",
          :purchaseDate=>"23-01-2023",
          :purchaseDesc=>"items",
          :item=>"1",
          :operationType=>"3",
          :quantity=>"1",
          :expiryTime=>10,
          :otherUrl=>"https://example/webhook/acledas/return?app_checkout=0&order_number=R156303026",
        }
      )
    end
  end

  describe '#gateway_params' do
    it 'return gateway_params' do
      acleda_method = create(:acleda_xpay_mpgs_payment_method, :xpay)
      payment = create(:acleda_payment, number: 'PXDMNSPA', payment_method: acleda_method, order: order, created_at: Date.new(2023, 01, 23))

      allow_any_instance_of(described_class).to receive(:start_connection)
      allow_any_instance_of(described_class).to receive(:update_payment_source)
      allow_any_instance_of(described_class).to receive(:json_response).and_return({
        'result' => {
          'sessionid' => 'SESSION-ID',
          'xTran' => {
            'paymentTokenid' => 'PAYMENT-TOKEN-ID'
          }
        }
      })

      context = described_class.new(payment)
      expect(context.gateway_params).to eq(
        :merchantID=>"Fake-Ao01Lr/y10389Ww82q1Z7meWY=",
        :sessionid=>"SESSION-ID",
        :paymenttokenid=>"PAYMENT-TOKEN-ID",
        :description=>"items",
        :expirytime=>10,
        :amount=>"29.99",
        :quantity=>"1",
        :Item=>"1",
        :invoiceid=>"R156303026",
        :currencytype=>"USD",
        :transactionID=>"PXDMNSPA",
        :successUrlToReturn=>"https://example/webhook/acledas/success?app_checkout=0&order_number=R156303026",
        :errorUrl=>"https://example/webhook/acledas/error?app_checkout=0&order_number=R156303026",
        :companyName=>"BookMe+",
        :companyLogo=>ActionController::Base.helpers.image_url('vpago/payway/acleda_merchant_logo_300x300.png')
      )
    end
  end
end
