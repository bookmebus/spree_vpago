module Spree
  module Miniapp
    # Partner Session Initialization API (ACLEDA Mini App Integration Spec, Step 01).
    # ACLEDA (server-to-server) POSTs { phone, first_name, last_name }; we return a
    # session-based miniAppUrl for ACLEDA to open in the WebView.
    class AcledasController < Spree::Api::V2::BaseController
      # POST /miniapp/acleda
      def create
        result = ::Vpago::AcledaMiniApp::Session::Create.call(
          phone: session_params[:phone],
          first_name: session_params[:first_name],
          last_name: session_params[:last_name]
        )

        if result.success?
          render json: { message: 'SUCCESS', miniAppUrl: result.value[:mini_app_url] }
        else
          render json: { message: 'FAILED', error: result.error.to_s }, status: :unprocessable_entity
        end
      end

      private

      def session_params
        params.permit(:phone, :first_name, :last_name)
      end
    end
  end
end
