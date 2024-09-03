module Spree
  module Admin
    module PaymentsControllerDecorator
      def self.prepended(base)
        base.before_action :set_vpago_payment_source, only: %i[create update]
      end

      def set_vpago_payment_source
        payment_method ||= Spree::PaymentMethod.find(params[:payment][:payment_method_id])
        return unless payment_method.vpago_payment?

        source_params = { payment_option: payment_method.preferred_payment_option }
        params[:payment][:source_attributes] = source_params
      end
    end
  end
end

Spree::Admin::PaymentsController.prepend(Spree::Admin::PaymentsControllerDecorator)
