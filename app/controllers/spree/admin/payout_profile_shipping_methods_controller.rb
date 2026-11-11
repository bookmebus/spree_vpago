module Spree
  module Admin
    class PayoutProfileShippingMethodsController < Spree::Admin::ResourceController
      before_action :redirect_to_object, only: [:index]

      belongs_to 'spree/shipping_method'

      def redirect_to_object
        if parent.payout_profile_shipping_methods.any?
          redirect_to edit_object_url(parent.payout_profile_shipping_methods.first)
        else
          redirect_to new_object_url
        end
      end

      def model_class
        Spree::PayoutProfileShippingMethod
      end
    end
  end
end
