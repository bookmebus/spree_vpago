module Spree
  module Admin
    class PayoutProfileProductsController < Spree::Admin::ResourceController
      before_action :redirect_to_object, only: [:index]

      belongs_to 'spree/product', find_by: :slug

      def redirect_to_object
        if parent.payout_profile_products.any?
          redirect_to edit_object_url(parent.payout_profile_products.first)
        else
          redirect_to new_object_url
        end
      end

      def model_class
        Spree::PayoutProfileProduct
      end
    end
  end
end
