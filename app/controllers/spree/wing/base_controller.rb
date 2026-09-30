module Spree
  module Wing
    class BaseController < ::ApplicationController
      before_action :wing_http_authenticate!

      rescue_from ActiveRecord::RecordNotFound, with: :not_found

      def wing_http_authenticate!
        wing_payment_method = Spree::PaymentMethod.find_by(type: Spree::PaymentMethod::TYPE_WINGSDK)

        authenticate_or_request_with_http_basic do |username, password|
          return false unless wing_payment_method.present?

          if wing_payment_method.preferred_basic_auth_username.blank? ||
             wing_payment_method.preferred_basic_auth_password.blank?
            return false
          end

          username == wing_payment_method.preferred_basic_auth_username &&
            password == wing_payment_method.preferred_basic_auth_password
        end
      end

      def not_found
        render json: { response_code: 404, response_msg: I18n.t(:resource_not_found, scope: 'spree.api') }, status: 404
      end
    end
  end
end
