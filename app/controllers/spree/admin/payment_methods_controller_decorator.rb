module Spree
  module Admin
    module PaymentMethodsControllerDecorator
      def scope
        scope = current_store.payment_methods_including_vendor.accessible_by(current_ability, :index)

        if params[:tab] == 'vendors'
          scope = scope.where.not(vendor_id: nil)
        elsif params[:tab] == 'tenants'
          scope = scope.joins(:vendor)
                       .where.not(vendor_id: nil)
                       .where.not(spree_vendors: { tenant_id: nil })
        end

        scope
      end

      # overrdie
      # handling error response
      def create
        @payment_method = params[:payment_method].delete(:type).constantize.new(payment_method_params)
        @object = @payment_method
        set_current_store
        invoke_callbacks(:create, :before)
        if @payment_method.save
          invoke_callbacks(:create, :after)
          flash[:success] = Spree.t(:successfully_created, resource: Spree.t(:payment_method))
          redirect_to location_after_create
        else
          invoke_callbacks(:create, :fails)
          respond_with(@object) do |format|
            format.html { render action: :new, status: :unprocessable_entity }
            format.js { render layout: false, status: :unprocessable_entity }
          end
        end
      end

      # overrdie
      # handling error response
      def update
        invoke_callbacks(:update, :before)
        payment_method_type = params[:payment_method].delete(:type)
        if @payment_method['type'].to_s != payment_method_type
          @payment_method.update_columns(
            type: payment_method_type,
            updated_at: Time.current
          )
          @payment_method = scope.find(params[:id])
        end

        attributes = payment_method_params.merge(preferences_params)
        attributes.each do |k, _v|
          attributes.delete(k) if k.include?('password') && attributes[k].blank?
        end

        if @payment_method.update(attributes)
          set_current_store
          invoke_callbacks(:update, :after)
          flash[:success] = Spree.t(:successfully_updated, resource: Spree.t(:payment_method))
          redirect_to spree.edit_admin_payment_method_path(@payment_method)
        else
          invoke_callbacks(:update, :fails)
          respond_with(@payment_method) do |format|
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @payment_method.errors.full_messages.to_sentence, status: :unprocessable_entity }
          end
        end
      end
    end
  end
end

Spree::Admin::PaymentMethodsController.prepend(Spree::Admin::PaymentMethodsControllerDecorator)
