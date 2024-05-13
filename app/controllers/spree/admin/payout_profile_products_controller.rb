module Spree
  module Admin
    class PayoutProfileProductsController < Spree::Admin::ResourceController
      belongs_to 'spree/product', find_by: :slug

      def model_class
        Spree::PayoutProfileProduct
      end
    end
  end
end
