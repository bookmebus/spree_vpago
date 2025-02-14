module Spree
  class VpagoPaymentsController < ApplicationController
    layout 'vpago_payments'
    helper 'vpago/vpago_payments'

    skip_before_action :verify_authenticity_token, only: [:process_payment]

    # GET
    def checkout
      @payment = Vpago::PaymentFinder.new(params.permit!.to_h).find_and_verify

      return render_not_found unless @payment.present?
      return redirect_to @payment.processing_url, allow_other_host: true unless @payment.checkout?

      @order = @payment.order
    end

    # GET
    def processing
      @payment = Vpago::PaymentFinder.new(params.permit!.to_h).find_and_verify
      return render_not_found unless @payment.present?

      @order = @payment.order
      return redirect_to @payment.success_url, allow_other_host: true if @payment.completed?
    end

    # GET
    def success
      @payment = Vpago::PaymentFinder.new(params.permit!.to_h).find_and_verify
      return render_not_found unless @payment.present?

      @order = @payment.order
      return redirect_to @payment.processing_url, allow_other_host: true unless @payment.completed?
    end

    # POST
    def process_payment
      return render json: { status: :ok }, status: :ok if request.method != 'POST'

      @payment = Vpago::PaymentFinder.new(params.permit!.to_h).find_and_verify
      return render_not_found unless @payment.present?

      unless @payment.order.paid?
        Vpago::PaymentProcessorJob.perform_later(
          payment_number: @payment.number
        )
      end

      render json: { status: :ok }, status: :ok
    rescue StandardError => e
      Rails.logger.error("Failed to enqueued payment processor job: #{params} #{e.message}")
      render json: { status: :internal_server_error, message: 'Failed to enqueue payment processor job' }, status: :internal_server_error
    end

    def render_not_found
      respond_to do |format|
        format.html { render file: Rails.public_path.join('404.html'), status: :not_found, layout: false }
        format.json { render json: { status: :not_found }, status: :not_found }
      end
    end
  end
end
