module Spree
  module MiniApp
    # Wing Mini App WebView entry. Wing opens this page cold — no server-to-server
    # pre-step like ACLEDA/Vattanac — so the page itself calls getProfile and posts
    # the signed result to #create.
    class WingsController < ApplicationController
      include Spree::MiniAppConcern

      layout 'wing_mini_app'

      PROVIDER = 'wing_bank'.freeze

      # Both actions carry their own HMAC (ProfileVerifier / WebhookVerifier), and
      # neither has an authenticated session for a CSRF token to protect.
      skip_before_action :verify_authenticity_token, only: %i[create callback]

      def show; end

      def create
        result = ::Vpago::WingMiniApp::Session::Create.call(
          profile: profile_params.to_h,
          gate: session_gate(PROVIDER)
        )

        if result.success?
          render json: { message: 'SUCCESS', miniAppUrl: result.value[:mini_app_url] }
        else
          render json: { message: 'FAILED', error: result.error.to_s }, status: failure_status(result)
        end
      end

      # Wing POSTs its settlement here. Its own action rather than
      # VpagoPaymentsController#process_payment, which is shaped around browser
      # returns from other gateways — return_params merging, the ABA reviewing-mode
      # branch, the internal_client flag — none of which a server-to-server webhook
      # sends.
      def callback
        payment = ::Vpago::PaymentFinder.new(params.permit!.to_h).find_and_verify

        return render json: { status: 'not_found' }, status: :not_found if payment.nil?

        ::Vpago::PaymentProcessorJob.perform_later(payment_number: payment.number) unless payment.order.paid?

        render json: { status: 'ok' }, status: :ok
      end

      private

      def profile_params
        params.require(:profile).permit(
          :id, :appId, :firstName, :lastName, :middleName, :fullName, :sex, :age, :nationality,
          :phone, :email, :city, :country, :address, :occupation, :addrCode, :dobFull, :nidNumber,
          :nidType, :nidExpirationDate, :lang, :appVersion, :osVersion, :secret_key
        )
      end
    end
  end
end
