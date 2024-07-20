module Spree
  module Admin
    class PayoutProfilesController < Spree::Admin::ResourceController
      before_action :load_types

      skip_before_action :load_resource, only: %i[index verify_with_bank]

      create.after :reset_verification
      update.after :reset_verification

      update.after :save_defaults!
      create.after :save_defaults!

      # when updated, active must be false.
      # call verify_with_bank to reactivate with bank.
      def reset_verification
        @object.reset_verification!
      end

      def save_defaults!
        instance = Spree::PayoutProfile.find(@object.id)

        instance.default = Spree::Store.default.name == instance.name
        instance.set_default_preferences if instance.respond_to?(:set_default_preferences)
        instance.save!
      end

      def load_types
        @types = ['Spree::PayoutProfiles::PaywayV2']
      end

      def verify_with_bank
        @object = Spree::PayoutProfile.find(params[:id])

        instance = if @object.registered_in_bank?
                     request_updater.new(@object)
                   else
                     request_creator.new(@object)
                   end

        if instance.call
          flash[:success] = flash_message_for(@object, :successfully_updated)
          redirect_to edit_object_url(@object)
        else
          flash[:error] = instance.error_messages.to_s
          redirect_to edit_object_url(@object)
        end
      end

      def request_updater
        ::Vpago::PayoutProfiles::Payway::PayoutProfileRequestUpdater
      end

      def request_creator
        ::Vpago::PayoutProfiles::Payway::PayoutProfileRequestCreator
      end

      def index
        @search = Spree::PayoutProfile.ransack(params[:q])
        @payout_profiles = @search.result.page(page).per(per_page).order(default: :desc)
      end

      # override
      def location_after_save
        edit_object_url(@object)
      end

      # override
      # permit all attributes for now.
      def permitted_resource_params
        key = ActiveModel::Naming.param_key(@object)
        permit_keys = params.require(key).keys

        params.require(key).permit(permit_keys)
      end

      # override
      def model_class
        Spree::PayoutProfile
      end

      def page
        params[:page] || 1
      end

      def per_page
        params[:per_page] || 12
      end
    end
  end
end
