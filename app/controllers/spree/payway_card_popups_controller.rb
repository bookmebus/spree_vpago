module Spree
  class PaywayCardPopupsController < ApplicationController
    layout 'payway'
    before_action :load_payment, only: [:show]

    def show
      if @payment.present?
        @client_redirect = ::Vpago::Payway::Checkout.new(@payment)
      end
    end

    def load_payment
      @payment = ::Spree::Payment.find_by(number: params[:payment_number])
    end
  end
end
