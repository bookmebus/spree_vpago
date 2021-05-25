module Spree
  module Api
    module V2
      module Storefront
        class PaymentsController < ::Spree::Api::V2::ResourceController
          def show
            @payment = ::Spree::Payment.find_by(number: params[:id])

            raise ActiveRecord::RecordNotFound if @payment.nil? || payment_invalid? || !vpago_payment_method?

            @result = ::Vpago::PaymentRedirectHandler.new(@payment)

            if @result.error_message.present?
              render_error_payload(@result.error_message)
            else
              render_serialized_payload { serialize_resource(@result) }
            end
          end

          def vpago_payment_method?
            @payment.payment_method.type == 'Spree::Gateway::Payway'
          end

          def payment_invalid?
            ::Spree::Payment::INVALID_STATES.include?(@payment.state)
          end

          def resource_serializer
            Spree::V2::Storefront::PaymentRedirectSerializer
          end
        end
      end
    end
  end
end
