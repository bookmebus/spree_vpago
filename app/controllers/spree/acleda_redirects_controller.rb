module Spree
  class AcledaRedirectsController < ApplicationController
    layout 'acleda'
    before_action :load_payment, only: [:show]

    def show
      if @payment.present?
        options = {
          app_checkout: true
        }

        @client_redirect = ActiveRecord::Base.connected_to(role: :writing) do
          ::Vpago::Acleda::Checkout.new(@payment, options)
        end
      end
    end

    def load_payment
      @payment = ::Spree::Payment.find_by(number: params[:payment_number])
    end
  end
end
