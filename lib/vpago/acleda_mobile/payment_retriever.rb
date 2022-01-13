module Vpago
  module AcledaMobile
    class PaymentRetriever
      attr_accessor :payment

      def initialize(options)
        @options = options
      end

      def call
        find_payment if data_valid?
      end

      def data_valid?
        service = Vpago::AcledaMobile::CallbackValidator.new(@options)
        service.valid?
      end

      def find_payment
        @payment = Spree::Payment.find_by(number: @options[:PaymentTokenId])
      end
    end
  end
end
