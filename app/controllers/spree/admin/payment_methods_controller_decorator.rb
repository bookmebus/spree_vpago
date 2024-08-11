module Spree
  module Admin
    module PaymentMethodsControllerDecorator
      def scope
        scope = current_store.payment_methods_including_vendor.accessible_by(current_ability, :index)
        scope = scope.where.not(vendor_id: nil) if params[:tab] == 'vendors'
        scope
      end
    end
  end
end

Spree::Admin::PaymentMethodsController.prepend(Spree::Admin::PaymentMethodsControllerDecorator)
