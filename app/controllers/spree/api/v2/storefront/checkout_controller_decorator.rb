module Spree
  module Api
    module V2
      module Storefront
        module CheckoutControllerDecorator
          def self.prepended(base)
            base.skip_before_action :ensure_order, only: [:request_update_payment]
          end

          # :order_token, :payment_number, :ignore_on_failed
          def request_update_payment
            # this action is mostly called after order is completed.
            # spree_current_order will be nil in this case, so we need to manual find.
            order = find_order_by_token(params[:order_token])
            ignore_on_failed = params[:ignore_on_failed] == true

            if order.paid?
              render_serialized_payload { serialize_resource(order) }
            else
              payment = find_payment(order, params[:payment_number])
              context = payment.request_update(ignore_on_failed: ignore_on_failed)

              if context.success? && context.error_message.blank?
                render_serialized_payload { serialize_resource(order) }
              else
                render_error_payload(context.error_message)
              end
            end
          end

          # :order_token, :ignore_on_failed
          def request_update_all_payments
            order = find_order_by_token(params[:order_token])
            ignore_on_failed = params[:ignore_on_failed] == true

            return render_serialized_payload { serialize_resource(order) } if order.paid?

            # check if there is a completed payment
            order.payments.processing.each do |payment|
              context = payment.request_update(ignore_on_failed: ignore_on_failed)
              return render_serialized_payload { serialize_resource(order) } if context.success? && payment.completed?
            end

            head :unprocessable_entity
          end

          def payment_redirect
            payments = spree_current_order.payments
            raise ActiveRecord::RecordNotFound if payments.blank?

            last_payment = payments.last
            payment_redirect = ::Vpago::PaymentRedirectHandler.new(
              payment: last_payment,
              override_return_deeplink_url: params[:override_return_deeplink_url]
            ).process

            if payment_redirect.error_message.blank?
              render_serialized_payload do
                payment_redirect_serializer.new(payment_redirect, params: serializer_params).serializable_hash
              end
            else
              render_error_payload(payment_redirect.error_message)
            end
          end

          def payment_redirect_serializer
            Spree::V2::Storefront::PaymentRedirectSerializer
          end

          private

          def find_payment(order, payment_number)
            payment = order.payments.find_by(number: payment_number)

            raise ActiveRecord::RecordNotFound if payment.nil?

            payment
          end

          def find_order_by_token(token)
            order = Spree::Order.find_by(token: token)
            raise ActiveRecord::RecordNotFound if order.nil?
            raise ActiveRecord::RecordNotFound if order.payments.blank?

            order
          end
        end
      end
    end
  end
end

Spree::Api::V2::Storefront::CheckoutController.prepend(Spree::Api::V2::Storefront::CheckoutControllerDecorator)
