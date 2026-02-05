module Spree
  class VpagoPaymentsController < ApplicationController
    layout 'vpago_payments'
    helper 'vpago/vpago_payments'

    skip_before_action :verify_authenticity_token, only: %i[process_payment true_money_process_payment]

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from CanCan::AccessDenied, with: :access_denied

    # GET
    def checkout
      @payment = Vpago::PaymentFinder.new(params.permit!.to_h).find_and_verify
      raise ActiveRecord::RecordNotFound unless @payment.present?

      return redirect_to @payment.processing_url, allow_other_host: true unless @payment.checkout?

      @order = @payment.order
    end

    # GET
    def processing
      @payment = Vpago::PaymentFinder.new(params.permit!.to_h).find_and_verify
      raise ActiveRecord::RecordNotFound unless @payment.present?

      @order = @payment.order
    end

    # GET
    def success
      @payment = Vpago::PaymentFinder.new(params.permit!.to_h).find_and_verify
      raise ActiveRecord::RecordNotFound unless @payment.present?

      @order = @payment.order
      raise CanCan::AccessDenied unless @order.completed?
    end

    # POST
    def process_payment
      return render json: { status: :ok }, status: :ok if request.method != 'POST'

      return_params = sanitize_return_params
      @payment = Vpago::PaymentFinder.new(return_params).find_and_verify
      return render_not_found unless @payment.present?

      unless @payment.order.paid?
        enqueued_at = Time.now.to_f
        log_enqueue_start(@payment, enqueued_at, return_params)

        Vpago::PaymentProcessorJob.perform_later(payment_number: @payment.number, enqueued_at: enqueued_at)
      end

      render json: { status: :ok }, status: :ok
    rescue StandardError => e
      log_enqueue_error(e)
      render json: { status: :internal_server_error, message: 'Failed to enqueue payment processor job' }, status: :internal_server_error
    end

    # POST
    def true_money_process_payment
      return render json: { status: { code: '000001', message: 'success' }, data: nil }, status: :ok if request.method != 'POST'

      @payment = Spree::Payment.find_by(number: params.dig(:data, :external_ref_id))
      return render_not_found unless @payment

      unless @payment.order.paid?
        enqueued_at = Time.now.to_f
        log_enqueue_start(@payment, enqueued_at)

        Vpago::PaymentProcessorJob.perform_later(payment_number: @payment.number, enqueued_at: enqueued_at)
      end

      render json: { status: { code: '000001', message: 'success' }, data: nil }, status: :ok
    rescue StandardError => e
      log_enqueue_error(e)
      render json: { status: :internal_server_error, message: 'Failed to enqueue payment processor job' }, status: :internal_server_error
    end

    private

    def sanitize_return_params
      sanitized_params = params.permit!.to_h

      # In ABA case, it returns params in side return params.
      sanitized_params.merge!(JSON.parse(sanitized_params.delete(:return_params))) if sanitized_params[:return_params].present?

      sanitized_params
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

    def log_enqueue_start(payment, enqueued_at, return_params = {})
      Rails.logger.info(
        {
          event: 'vpago.payment_processor_job.enqueue',
          payment_number: payment.number,
          order_number: payment.order&.number,
          request_id: request.request_id,
          payment_method_type: payment.payment_method&.type,
          payment_method_name: payment.payment_method&.name,
          gateway: detect_payway_gateway_version(payment.payment_method),
          tran_id: (return_params[:tran_id] || return_params['tran_id']),
          enqueued_at: enqueued_at
        }
      )
    end

    def log_enqueue_error(error)
      Rails.logger.error(
        {
          event: 'vpago.payment_processor_job.enqueue.error',
          request_id: request.request_id,
          payment_number: @payment&.number,
          error_class: error.class.name,
          error_message: error.message
        }
      )
    end

    def detect_payway_gateway_version(payment_method)
      return nil unless payment_method
      return 'payway_v2' if payment_method.type_payway_v2?
      return 'payway_v1' if payment_method.type_payway?

      nil
    end
  end
end
