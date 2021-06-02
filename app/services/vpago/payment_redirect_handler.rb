require 'faraday'

module Vpago
  class PaymentRedirectHandler
    include ActiveModel::Serialization

    attr_accessor :redirect_options, :error_message
    attr_reader :payment

    delegate      :id, :amount, :response_code, :number, :state,
                  :payment_method_id, :payment_method_name,
              to: :payment

    def initialize(payment:)
      @payment = payment
    end

    def process
      validate_payment
      check_and_process_payment

      self
    end

    def check_and_process_payment
      payment_option = @payment.payment_method.preferences[:payment_option]

      @payment.process!
      payment_option == 'abapay' ? process_abapay_deeplink : process_payway_card
    end

    def process_payway_card
      ## TO DO: generate redirect url
      data = {
        href: "#{ENV['DEFAULT_URL_HOST']}/payway_card_popups?payment_number=#{@payment.number}"
      }

      @redirect_options = data
    end

    def process_abapay_deeplink
      send_process_payment

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

      @response = conn.post(abapay_payment.action_url, gateway_params) do |request|
        request.headers["Referer"] = ENV['DEFAULT_URL_HOST']
      end
    end

    def validate_payment
      raise ActiveRecord::RecordNotFound if !payment_valid || !vpago_payment_method

      true
    end

    def vpago_payment_method
      @payment.payment_method.type == 'Spree::Gateway::Payway'
    end

    def payment_valid
      !::Spree::Payment::INVALID_STATES.include?(@payment.state)
    end
  end
end
