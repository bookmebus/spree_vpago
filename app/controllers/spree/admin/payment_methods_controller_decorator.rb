module Spree
  module Admin
    module PaymentMethodsControllerDecorator
      def scope
        scope = current_store.payment_methods_including_vendor.accessible_by(current_ability, :index)
        scope = scope.where.not(vendor_id: nil) if params[:tab] == 'vendors'
        scope
      end

      def calculate_allow_role_value(params)
        params.slice(*Spree::PaymentMethod::BIT_FIELDS.keys).values.each_with_index.sum { |v, i| v.to_i * (2**i) }
      end

      # override
      def preferences_params
        key = ActiveModel::Naming.param_key(@payment_method)
        return {} unless params[key]

        allow_role = calculate_allow_role_value(params[key])
        params.require(key).permit.except(*Spree::PaymentMethod::BIT_FIELDS.keys).merge(preferred_allow_role: allow_role)
      end
    end
  end
end

Spree::Admin::PaymentMethodsController.prepend(Spree::Admin::PaymentMethodsControllerDecorator)
