module Spree
  module Api
    module V2
      module Storefront
        class PaywayCardsController < ApplicationController
          layout 'payway'

          def show
            @payment = ::Spree::Payment.find_by(number: params[:payment_id])

            if @payment.present?
              @client_redirect = ::Vpago::Payway::Checkout.new(@payment)
            end
          end
        end
      end
    end
  end
end
