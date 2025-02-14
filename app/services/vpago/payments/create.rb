# Original `Vpago::Payments::Create` requires `Wallet::CreatePaymentSource`.
# We override it to avoid that requirement.
module Vpago
  module Payments
    class Create
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
        payment = order.payments.find_or_initialize_by(
          state: :checkout,
          amount: order.order_total_after_store_credit,
          payment_method: payment_method
        )

        if payment_method&.source_required? && payment.source.blank?
          payment.source = payment_method.payment_source_class.new(params[:source_attributes])
          payment.save!
        end

        return failure(payment) if payment.errors.any?

        success(order: order)
      end
    end
  end
end
