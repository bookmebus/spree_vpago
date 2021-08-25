require 'spec_helper'

RSpec.describe Spree::Wing::BaseController, type: :controller do
  controller do
    def index
      render json: {message: :ok}
    end
  end

  describe 'Basic Auth' do
    context "when no wing payment method" do
      it 'return access denied' do
        get :index
        expect(response.status).to eq 401
      end
    end

    context "when no username auth and password auth set in wing payment method" do
      it 'return access denied' do
        create(:wing_sdk_gateway)

        get :index
        expect(response.status).to eq 401
      end
    end
    
    context "username and password not match" do
      it 'return access denied' do
        wing_gateway = create(:wing_sdk_gateway)
        wing_gateway.preferred_basic_auth_username = 'wing'
        wing_gateway.preferred_basic_auth_password = '123'
        wing_gateway.save

        user = 'test'
        pwd = '123'
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user, pwd)

        get :index
        expect(response.status).to eq 401
      end
    end

    context "username and password correct" do
      it 'allow access' do
        wing_gateway = create(:wing_sdk_gateway)
        wing_gateway.preferred_basic_auth_username = 'wing'
        wing_gateway.preferred_basic_auth_password = '123'
        wing_gateway.save

        user = wing_gateway.preferred_basic_auth_username
        pwd = wing_gateway.preferred_basic_auth_password
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user, pwd)

        get :index
        expect(response.status).to eq 200
      end
    end
  end
end
