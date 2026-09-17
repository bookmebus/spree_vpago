# Order-based counterpart to Spree::VpagoPaymentsController, for orders where
# order_total_after_store_credit is zero -- store credit covering the order in full, cash-on with
# nothing left to pay after store credit, or a free event. Deliberately client-agnostic to whether
# a Spree::Payment exists underneath (store credit's checkout-state payment is real; a free event
# has none at all -- see Vpago::OrderDecorator#vpago_order_processing_url and
# Vpago::OrderProcessor). No checkout-form step is ever needed here either way -- clients land
# straight on `processing`.
#
# processing/success render spree/vpago_shared/{processing,success} (made @payment-optional there)
# rather than maintaining a near-duplicate pair under spree/vpago_orders/ -- the two flows share
# the same card layout, Stimulus controller, and booking-details partial; only the payment info
# section and a few dataset attributes differ, and those are already guarded on @payment being
# present.
module Spree
  class VpagoOrdersController < ApplicationController
    layout 'vpago_payments'
    helper 'vpago/vpago_payments'

    skip_before_action :verify_authenticity_token, only: %i[process_order]

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from CanCan::AccessDenied, with: :access_denied

    before_action :find_order, only: %i[processing success]
    after_action :allow_iframe_embedding, only: %i[processing success]

    # GET
    def processing
      return redirect_to @order.success_url, allow_other_host: true if @order.completed?

      VpagoLogger.log(label: 'Spree::VpagoOrdersController#processing', data: vpago_log_context)
      render 'spree/vpago_shared/processing'
    end

    # GET
    def success
      raise CanCan::AccessDenied unless @order.completed?

      VpagoLogger.log(label: 'Spree::VpagoOrdersController#success', data: vpago_log_context)
      render 'spree/vpago_shared/success'
    end

    # POST
    def process_order
      return render json: { status: :ok }, status: :ok if request.method != 'POST'

      @order = Vpago::OrderFinder.new(params.permit!.to_h).find_and_verify

      if @order.nil?
        VpagoLogger.error(
          label: 'Spree::VpagoOrdersController#process_order order_not_found',
          data: vpago_log_context(params: params.permit!.to_h)
        )
        return render_not_found
      end

      VpagoLogger.log(label: 'Spree::VpagoOrdersController#process_order order_found', data: vpago_log_context)

      unless @order.completed?
        VpagoLogger.log(
          label: 'Spree::VpagoOrdersController#process_order enqueue_order_processor_job',
          data: vpago_log_context
        ) { Vpago::OrderProcessorJob.perform_later(order_number: @order.number) }
      end

      render json: { status: :ok }, status: :ok
    rescue StandardError => e
      VpagoLogger.error(
        label: 'Spree::VpagoOrdersController#process_order failed',
        data: vpago_log_context(error_class: e.class.name, error_message: e.message, backtrace: e.backtrace&.first(5))
      )
      render json: { status: :internal_server_error, message: 'Failed to enqueue order processor job' }, status: :internal_server_error
    end

    private

    def find_order
      @order = Vpago::OrderFinder.new(params.permit!.to_h).find_and_verify
      @payment = @order.payments.first if @order.present? # optional, for shared partials
      raise ActiveRecord::RecordNotFound unless @order.present?
    end

    # frame-ancestors (set above) supersedes X-Frame-Options in modern
    # browsers, but the default SAMEORIGIN header would still block legacy
    # browsers from embedding these pages, so drop it for the iframe actions.
    def allow_iframe_embedding
      response.headers.delete('X-Frame-Options')
    end

    def render_not_found
      respond_to do |format|
        format.html { render file: Rails.public_path.join('404.html'), status: :not_found, layout: false }
        format.json { render json: { status: :not_found }, status: :not_found }
      end
    end

    def access_denied
      respond_to do |format|
        format.html { render file: Rails.public_path.join('422.html'), status: :not_found, layout: false }
        format.json { render json: { status: :unauthorized }, status: :unauthorized }
      end
    end

    def vpago_log_context(extra = {})
      {
        timestamp: Time.current.utc.iso8601(3),
        remote_ip: request.remote_ip,
        order_number: @order&.number,
        request_id: request.request_id
      }.merge(extra)
    end
  end
end
