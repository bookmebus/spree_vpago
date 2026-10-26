module Spree
  module MiniApp
    # Partner Session Initialization API (ACLEDA Mini App Integration Spec, Step 01).
    # ACLEDA POSTs { phone, first_name, last_name } signed with X-Acleda-Signature, and
    # gets back a session-based miniAppUrl to open in the WebView.
    class AcledasController < Spree::Api::V2::BaseController
      include Spree::MiniAppConcern

      PROVIDER = 'acleda_bank'.freeze

      # POST /mini_app/acleda
      def create
        result = ::Vpago::AcledaMiniApp::Session::Create.call(
          phone: session_params[:phone],
          first_name: session_params[:first_name],
          last_name: session_params[:last_name],
          signature: request.headers['X-Acleda-Signature'],
          gate: session_gate(PROVIDER)
        )

        if result.success?
          render json: { message: 'SUCCESS', miniAppUrl: result.value[:mini_app_url] }
        else
          render json: { message: 'FAILED', error: result.error.to_s }, status: failure_status(result)
        end
      end

      private

      def session_params
        params.permit(:phone, :first_name, :last_name)
      end
    end
  end
end
