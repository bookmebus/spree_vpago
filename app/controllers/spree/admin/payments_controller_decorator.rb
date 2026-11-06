module Spree
  module Admin
    module PaymentsControllerDecorator
      def self.prepended(base)
        base.before_action :set_vpago_payment_source, only: %i[create update]
      end

      def set_vpago_payment_source
        payment_method ||= Spree::PaymentMethod.find(params[:payment][:payment_method_id])
        return unless payment_method.vpago_payment?

        source_params = { payment_option: payment_method.try(:preferred_payment_option) }
        params[:payment][:source_attributes] = source_params
      end

      # override
      # For vpago gateways created from the admin backend, we skip immediate processing
      # and keep the payment in `checkout` state so the admin can open the QR checkout
      # URL and pay on behalf of the customer. The bank webhook
      # (process_payment -> Vpago::PaymentProcessorJob) completes the order once paid.
      def create
        return super unless @payment_method&.vpago_payment?

        invoke_callbacks(:create, :before)

        @payment = @order.payments.build(object_params)

        if @payment.save
          invoke_callbacks(:create, :after)
          flash[:success] = flash_message_for(@payment, :successfully_created)
          redirect_to spree.admin_order_payments_path(@order)
        else
          invoke_callbacks(:create, :fails)
          flash[:error] = Spree.t(:payment_could_not_be_created)
          render :new, status: :unprocessable_entity
        end
      rescue Spree::Core::GatewayError => e
        invoke_callbacks(:create, :fails)
        flash[:error] = e.message.to_s
        redirect_to spree.new_admin_order_payment_path(@order)
      end

      # override
      # Before the normal `process!` re-runs the gateway, reset a stuck vpago
      # payment back to `checkout`. Admin reprocess only — the automatic webhook
      # path is untouched (it auto-resets `failed` alone).
      def fire
        reset_stuck_payment_for_reprocess!
        super
      end

      private

      def reset_stuck_payment_for_reprocess!
        return unless params[:e] == 'process'
        return unless @payment&.payment_method&.vpago_payment?
        return unless @payment.can_reset_for_retry?

        @payment.reset_for_retry!
      end
    end
  end
end

Spree::Admin::PaymentsController.prepend(Spree::Admin::PaymentsControllerDecorator)
