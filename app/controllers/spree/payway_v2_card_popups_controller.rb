module Spree
  class PaywayV2CardPopupsController < ApplicationController
    layout 'payway_v2'
    before_action :load_payment, only: [:show]

    def show
      if @payment.present?
        options = {
          app_checkout: true
        }

        @client_redirect = ::Vpago::PaywayV2::Checkout.new(@payment, options)
      end
    end

    def load_payment
      @payment = ::Spree::Payment.find_by(number: params[:payment_number])
    end
  end
end
