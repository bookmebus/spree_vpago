module Vpago
  class PaymentProcessor
    attr_accessor :payment, :error

    def initialize(payment:)
      @payment = payment
      @error = nil
    end

    def call
      process_payment!
      return process_order if payment.completed? || payment.pending?

      mark_payment_process_failed
    rescue Spree::Core::GatewayError, StateMachines::InvalidTransition => e
      mark_payment_process_failed(e.message)
    end

    private

    def process_payment!
      user_informer.payment_is_processing(processing: true)
      payment.process!
    end

    def process_order
      user_informer.order_is_processing(processing: true)
      completer = Spree::Checkout::Complete.new.call(order: payment.order)

      if completer.success?
        mark_order_process_completed
      else
        mark_order_process_failed(completer.error.to_s)
      end
    end

    def mark_order_process_completed
      payment.capture! if payment.pending?
      user_informer.order_is_completed(processing: false)
    end

    def mark_order_process_failed(message)
      user_informer.order_process_failed(processing: payment.pending?, log_message: message)

      if payment.pending?
        payment.void_transaction!
        user_informer.payment_is_refunded(processing: false)
      end

      failure(message)
    end

    def mark_payment_process_failed(message = nil)
      message ||= Spree.t(:payment_process_failed)

      user_informer.payment_process_failed(processing: false, log_message: message)
      failure(message)
    end

    def user_informer
      @user_informer ||= ::Vpago::UserInformers::Firebase.new(payment.order)
    end

    def success?
      @error.nil?
    end

    def failure(error)
      @error = error
    end
  end
end
