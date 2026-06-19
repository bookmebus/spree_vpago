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

      VpagoLogger.log(label: 'Spree::VpagoPaymentsController#checkout', data: vpago_log_context)
    end

    # GET
    def processing
      @payment = Vpago::PaymentFinder.new(params.permit!.to_h).find_and_verify
      raise ActiveRecord::RecordNotFound unless @payment.present?

      @order = @payment.order

      VpagoLogger.log(label: 'Spree::VpagoPaymentsController#processing', data: vpago_log_context)
    end

    # GET
    def success
      @payment = Vpago::PaymentFinder.new(params.permit!.to_h).find_and_verify
      raise ActiveRecord::RecordNotFound unless @payment.present?

      @order = @payment.order
      raise CanCan::AccessDenied unless @order.completed?

      VpagoLogger.log(label: 'Spree::VpagoPaymentsController#success', data: vpago_log_context)
    end

    # GET
    def check_transaction
      @payment = Vpago::PaymentFinder.new(params.permit!.to_h).find_and_verify
      raise ActiveRecord::RecordNotFound unless @payment.present?

      return render json: { status: :success }, status: :ok if @payment.completed?
      return render json: { status: :failed }, status: :ok if @payment.failed?

      unless @payment.payment_method.support_check_transaction_api?
        VpagoLogger.log(label: 'Spree::VpagoPaymentsController#check_transaction unsupported', data: vpago_log_context)
        return render json: { status: :pending }, status: :ok
      end

      checker = VpagoLogger.log(
        label: 'Spree::VpagoPaymentsController#check_transaction',
        data: vpago_log_context
      ) { @payment.payment_method.check_transaction(@payment) }

      if checker.success?
        render json: { status: :success }, status: :ok
      elsif checker.try(:failed?) == true
        render json: { status: :failed }, status: :ok
      else
        render json: { status: :pending }, status: :ok
      end
    end

    # POST
    def process_payment
      return render json: { status: :ok }, status: :ok if request.method != 'POST'

      return_params = sanitize_return_params
      @payment = Vpago::PaymentFinder.new(return_params).find_and_verify

      if @payment.nil?
        VpagoLogger.error(
          label: 'Spree::VpagoPaymentsController#process_payment payment_not_found',
          data: vpago_log_context(params: return_params)
        )
        return render_not_found
      end

      VpagoLogger.log(label: 'Spree::VpagoPaymentsController#process_payment payment_found', data: vpago_log_context)

      # for ABA reviewing mode, we can disable pushback from bank, and only process it from our app UI instead.
      # This will give ABA team to know that we don't rely on just pushback and have fallback to process payment.
      if @payment.payment_method.type_payway_v2? && @payment.payment_method.reviewing_mode? && request_from_external_server?
        VpagoLogger.log(label: 'Spree::VpagoPaymentsController#process_payment skipped_reviewing_mode', data: vpago_log_context)
        return render json: { status: :ok }, status: :ok
      end

      unless @payment.order.paid?
        VpagoLogger.log(
          label: 'Spree::VpagoPaymentsController#process_payment enqueue_payment_processor_job',
          data: vpago_log_context
        ) { Vpago::PaymentProcessorJob.perform_later(payment_number: @payment.number) }
      end

      render json: { status: :ok }, status: :ok
    rescue StandardError => e
      VpagoLogger.error(
        label: 'Spree::VpagoPaymentsController#process_payment failed',
        data: vpago_log_context(error_class: e.class.name, error_message: e.message, backtrace: e.backtrace&.first(5))
      )
      render json: { status: :internal_server_error, message: 'Failed to enqueue payment processor job' }, status: :internal_server_error
    end

    # POST
    def true_money_process_payment
      return render json: { status: { code: '000001', message: 'success' }, data: nil }, status: :ok if request.method != 'POST'

      @payment = Spree::Payment.find_by(number: params.dig(:data, :external_ref_id))

      if @payment.nil?
        VpagoLogger.error(
          label: 'Spree::VpagoPaymentsController#true_money_process_payment payment_not_found',
          data: vpago_log_context(external_ref_id: params.dig(:data, :external_ref_id))
        )
        return render_not_found
      end

      unless @payment.order.paid?
        VpagoLogger.log(
          label: 'Spree::VpagoPaymentsController#true_money_process_payment enqueue_payment_processor_job',
          data: vpago_log_context
        ) { Vpago::PaymentProcessorJob.perform_later(payment_number: @payment.number) }
      end

      render json: { status: { code: '000001', message: 'success' }, data: nil }, status: :ok
    rescue StandardError => e
      VpagoLogger.error(
        label: 'Spree::VpagoPaymentsController#true_money_process_payment failed',
        data: vpago_log_context(error_class: e.class.name, error_message: e.message, backtrace: e.backtrace&.first(5))
      )
      render json: { status: :internal_server_error, message: 'Failed to enqueue payment processor job' }, status: :internal_server_error
    end

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

    def request_from_external_server?
      params[:internal_client].blank? || params[:internal_client] == 'false'
    end

    def vpago_log_context(extra = {})
      {
        timestamp: Time.current.utc.iso8601(3),
        remote_ip: request.remote_ip,
        payment_number: @payment&.number,
        order_number: @payment&.order&.number,
        payment_method_type: @payment&.payment_method&.type,
        payment_method_name: @payment&.payment_method&.name,
        request_id: request.request_id
      }.merge(extra)
    end
  end
end
