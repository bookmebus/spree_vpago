module Vpago
  class PaymentStatusMarker
    attr_accessor :payment, :error_message

    # :status, :description, :updated_by_user_id, updated_reason
    def initialize(payment, options={})
      @payment = payment
      @options = options

      @options[:status] =  @options[:status] || false
    end

    def call
      ActiveRecord::Base.transaction do
        update_payment_source
        update_payment_and_order
      end
    end

    private

    def update_payment_source
      source = @payment.source

      payment_status = @options[:status] ? 'success' : 'failed'
      source.payment_status = payment_status
      source.payment_description =  @options[:description]
      source.transaction_id = @options[:transaction_id] if @options[:transaction_id].present? ## for acleda, we already update the transaction_id at when checkout
      source.preferred_wing_response = @options[:wing_response]
      source.preferred_acleda_response = @options[:acleda_response]

      if @options[:status]
        source.updated_by_user_id = @options[:updated_by_user_id]
        source.updated_reason = @options[:updated_reason]
        source.updated_by_user_at = Time.zone.now
      end
      
      if(!source.save)
        @error_message = source.errors.full_messages.join('\n')
      end
    end

    def update_payment_and_order
      if @options[:status]
        transition_to_paid!
      else
        transition_to_failed!
      end
      
      order_updater
    end

    def transition_to_paid!
      complete_payment!
      complete_order!
    end

    def transition_to_failed!
      @payment.failure! if !@payment.failed?
      @payment.order.update(state: 'payment')
      
      notify_failed_payment
    end

    def order_updater
      @payment.order.update_with_updater!
    end

    def complete_payment!
      @payment.complete! if !@payment.completed?
    end

    def complete_order!
      return if @payment.order.completed?
      order = @payment.order
      order.finalize!
      order.update(state: 'complete', completed_at: Time.zone.now)
    end

    def notify_failed_payment
      Rails.logger.info("Gateway error check with: #{@options[:description]} and will be marked as failed")
    end
  end
end
