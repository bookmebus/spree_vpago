module Spree
  module Api
    module V2
      module Storefront
        module CheckoutControllerDecorator
          def self.prepended(base)
            base.skip_before_action :ensure_order, only: [:reload_payments]
          end

          def reload_payments
            # include completed orders
            order = Spree::Order.find_by(number: params[:number])

            spree_authorize! :update, order, order_token
            order.update_vpago_payments

            render_serialized_payload { serialize_resource(order) }
          end

          def payment_redirect
            payments = spree_current_order.payments
            raise ActiveRecord::RecordNotFound if payments.blank?

            last_payment = payments.last
            payment_redirect = ::Vpago::PaymentRedirectHandler.new(payment: last_payment).process

            if payment_redirect.error_message.blank?
              render_serialized_payload { payment_redirect_serializer.new(payment_redirect, params: serializer_params).serializable_hash }
            else
              render_error_payload(payment_redirect.error_message)
            end
          end

          def payment_redirect_serializer
            Spree::V2::Storefront::PaymentRedirectSerializer
          end
        end
      end
    end
  end
end

::Spree::Api::V2::Storefront::CheckoutController.prepend(::Spree::Api::V2::Storefront::CheckoutControllerDecorator)
