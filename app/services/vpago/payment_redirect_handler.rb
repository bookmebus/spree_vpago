require 'faraday'

module Vpago
  class PaymentRedirectHandler
    include ActiveModel::Serialization

    attr_accessor :redirect_options, :error_message
    attr_reader :payment

    delegate      :id, :amount, :response_code, :number, :state,
                  :payment_method_id, :payment_method_name,
              to: :payment

    def initialize(payment)
      @payment = payment
      @payment_method = @payment.payment_method
      @payment.process!

      should_process_abapay_deeplink
      should_process_payway_card
    end

    def should_process_payway_card
      return if @payment_method.preferences[:payment_option] != 'cards'

      ## TO DO: generate redirect url
      data = {
        href: "#{ENV['DEFAULT_URL_HOST']}/api/v2/storefront/payments/#{@payment.number}/payway_cards.html"
      }

      @redirect_options = data
    end

    def should_process_abapay_deeplink
      return if @payment_method.preferences[:payment_option] != 'abapay'

      @response = send_process_payment

      if @response.status == 200
        json_response = JSON.parse(@response.body)
        
        if json_response["status"] == "0"
          @redirect_options = json_response
        else
          @error_message = json_response["description"]
        end
      end
    end

    def send_process_payment
      abapay_payment = ::Vpago::Payway::Checkout.new(@payment)
      gateway_params = abapay_payment.gateway_params
      gateway_params[:payment_option] = 'abapay_deeplink'

      conn = Faraday::Connection.new do |faraday|
        faraday.request  :url_encoded
      end

     conn.post(abapay_payment.action_url, gateway_params)
    end
  end
end
