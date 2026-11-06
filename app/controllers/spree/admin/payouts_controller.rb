module Spree
  module Admin
    class PayoutsController < Spree::Admin::ResourceController
      belongs_to 'spree/order', find_by: :number

      skip_before_action :load_resource

      def index
        @payouts = parent.payouts
                         .order(:created_at)
                         .where(state: params[:state] || 'confirmed')
                         .includes(:payoutable, :payout_profile, payment: :order)
      end
    end
  end
end
