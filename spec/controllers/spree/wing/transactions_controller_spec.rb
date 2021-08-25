require 'spec_helper'

RSpec.describe Spree::Wing::TransactionsController, type: :controller do

  describe "GET show" do
    before(:each) do
      wing_gateway = create(:wing_sdk_gateway)
      wing_gateway.preferred_basic_auth_username = 'wing'
      wing_gateway.preferred_basic_auth_password = '123'
      wing_gateway.save

      user = wing_gateway.preferred_basic_auth_username
      pwd = wing_gateway.preferred_basic_auth_password
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user, pwd)
    end
  
    context "when payment source not found" do
      it 'return error with status 404' do
        get :show, params: {id: '09123'}

        json_response = JSON.parse(response.body)
        expect(response.status).to eq 404
        expect(json_response["response_code"]).to eq 404
        expect(json_response["response_msg"]).to eq "The resource you were looking for could not be found."
      end
    end

    context "when no wing response in payment source" do
      it 'return error with status 422' do
        wing_payment_source = create(:wing_sdk_payment_source)

        get :show, params: {id: wing_payment_source.transaction_id}

        json_response = JSON.parse(response.body)
        expect(response.status).to eq 422
        expect(json_response["response_code"]).to eq 422
        expect(json_response["response_msg"]).to eq "Unable to load response from wing"
      end
    end

    context "when payment source and wing response available" do
      it 'return success result' do
        wing_payment = create(:wing_sdk_payment)

        wing_response = {
          errorCode: "200",
          respType: "CINQURYRESP",
          amount: "29.99",
          remark: "12344321",
          customer_name: "Maneth Phan",
          customer_fee: "0",
          currency: "USD",
          wing_account: "0977707468",
          transaction_id: "ONL015162",
          transaction_date: 1629861312807,
          biller_name: "Reatrey Soun Kolap",
          biller_code: "2000"
        }.with_indifferent_access

        wing_payment_source = wing_payment.source
        wing_payment_source.preferred_wing_response = wing_response
        wing_payment_source.save
        wing_payment_source.reload

        get :show, params: {id: wing_payment_source.transaction_id}

        json_response = JSON.parse(response.body)
        expect(response.status).to eq 200
        expect(json_response["response_code"]).to eq 200
        expect(json_response["response_msg"]).to eq 'Transaction success'
        expect(json_response["customer_name"]).to eq wing_response["customer_name"]
        expect(json_response["amount"]).to eq wing_response["amount"]
        expect(json_response["currency"]).to eq wing_response["currency"]
        expect(json_response["transaction_id"]).to eq wing_response["transaction_id"]
        expect(json_response["transaction_date"]).to eq wing_response["transaction_date"]
        expect(json_response["partner_txn_id"]).to eq wing_payment.number
      end
    end
  end
end
