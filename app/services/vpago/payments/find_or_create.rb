# Replacement for Spree::Payments::Create. To look for existing payment instead of always create new one.
module Vpago
  module Payments
    class FindOrCreate
      prepend Spree::ServiceModule::Base

      def call(order:, params: {}) # rubocop:disable Lint/UnusedMethodArgument
        ApplicationRecord.transaction do
          run :find_payment_method
          run :find_or_create_payment
        end
      end

      def find_payment_method(order:, params:)
        payment_method = order.available_payment_methods.find { |pm| pm.id.to_s == params[:payment_method_id]&.to_s }
        return failure(nil, :payment_method_not_found) if payment_method.blank?

        success(order: order, params: params, payment_method: payment_method)
      end

      def find_or_create_payment(order:, params:, payment_method:)
        # Store credit is applied via the storefront's own POST .../checkout/add_store_credit,
        # never through create_payment. Its source_class (Spree::StoreCredit) has neither a
        # payment_method_id column nor the other fields a blank .new(...) below would need to
        # save, so falling through would raise ActiveModel::UnknownAttributeError instead of
        # producing a broken payment -- fail clearly instead.
        return failure(nil, :store_credit_must_be_applied_via_add_store_credit) if payment_method.is_a?(Spree::PaymentMethod::StoreCredit)

        payment = order.payments.find_or_initialize_by(
          state: :checkout,
          amount: order.order_total_after_store_credit,
          payment_method: payment_method
        )

        if payment_method&.source_required? && payment.source.blank?
          source_attributes = {
            payment_option: params[:payment_option],
            payment_method_id: payment_method.id,
            user_id: order.user&.id,
            gateway_payment_profile_id: params[:gateway_payment_profile_id],
            gateway_customer_profile_id: params[:gateway_customer_profile_id],
            last_digits: params[:last_digits],
            month: params[:month],
            year: params[:year],
            name: params[:name]
          }.compact

          payment.source = payment_method.payment_source_class.new(source_attributes)
        end

        payment.save!

        return failure(payment) if payment.errors.any?

        success(order: order)
      end
    end
  end
end
