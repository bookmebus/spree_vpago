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

      Rails.logger.info("[Vpago] Showing processing page for payment #{@payment.number} for order #{@order.number}")
    end

    # GET
    def success
      @payment = Vpago::PaymentFinder.new(params.permit!.to_h).find_and_verify
      raise ActiveRecord::RecordNotFound unless @payment.present?

      @order = @payment.order
      raise CanCan::AccessDenied unless @order.completed?

      Rails.logger.info("[Vpago] Showing success page for payment #{@payment.number} for order #{@order.number}")
    end

    # GET
    def check_transaction
      @payment = Vpago::PaymentFinder.new(params.permit!.to_h).find_and_verify
      raise ActiveRecord::RecordNotFound unless @payment.present?

      return render json: { status: :success }, status: :ok if @payment.completed?
      return render json: { status: :failed }, status: :ok if @payment.failed?

      if @payment.payment_method.support_check_transaction_api?
        Rails.logger.info("[Vpago] Checking transaction for payment #{@payment.number}")
        checker = @payment.payment_method.check_transaction(@payment)
        Rails.logger.info("[Vpago] Check transaction result for payment #{@payment.number} with success: #{checker.success?}, failed: #{checker.try(:failed?)}")

        if checker.success?
          render json: { status: :success }, status: :ok
        elsif checker.try(:failed?) == true
          render json: { status: :failed }, status: :ok
        else
          render json: { status: :pending }, status: :ok
        end
      else
        render json: { status: :pending }, status: :ok
      end
    end

    # POST
    def process_payment
      Rails.logger.info("[Vpago] Received payment notification: method=#{request.method}, params=#{params.to_unsafe_h}")
      return render json: { status: :ok }, status: :ok if request.method != 'POST'

      return_params = sanitize_return_params
      @payment = Vpago::PaymentFinder.new(return_params).find_and_verify

      if @payment.nil?
        Rails.logger.error("[Vpago] Payment not found for params: #{return_params}")
        return render_not_found
      end

      Rails.logger.info("[Vpago] Payment found: #{@payment&.number}, order: #{@payment&.order&.number}")

      # for ABA reviewing mode, we can disable pushback from bank, and only process it from our app UI instead.
      # This will give ABA team to know that we don't rely on just pushback and have fallback to process payment.
      if @payment.payment_method.type_payway_v2? && @payment.payment_method.reviewing_mode? && request_from_external_server?
        Rails.logger.info("[Vpago] Received payment notification from bank in reviewing mode, skipping processing: #{params}")
        return render json: { status: :ok }, status: :ok
      end

      unless @payment.order.paid?
        Rails.logger.info("[Vpago] Enqueuing payment processor job for payment #{@payment.number}: #{params}")
        Vpago::PaymentProcessorJob.perform_later(
          payment_number: @payment.number
        )
      end

      Rails.logger.info("[Vpago] Successfully enqueued payment processor job for payment #{@payment.number}: #{params}")
      render json: { status: :ok }, status: :ok
    rescue StandardError => e
      Rails.logger.error("[Vpago] Failed to enqueue payment processor job: #{params} #{e.message}")
      render json: { status: :internal_server_error, message: 'Failed to enqueue payment processor job' }, status: :internal_server_error
    end

    # POST
    def true_money_process_payment
      return render json: { status: { code: '000001', message: 'success' }, data: nil }, status: :ok if request.method != 'POST'

      @payment = Spree::Payment.find_by(number: params.dig(:data, :external_ref_id))
      return render_not_found unless @payment

      Vpago::PaymentProcessorJob.perform_later(payment_number: @payment.number) unless @payment.order.paid?
      Rails.logger.info("[Vpago] Successfully enqueued payment processor job for payment #{@payment.number}: #{params}")

      render json: { status: { code: '000001', message: 'success' }, data: nil }, status: :ok
    rescue StandardError => e
      Rails.logger.error("[Vpago] Failed to enqueue payment processor job: #{params} #{e.message}")
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
  end
end
