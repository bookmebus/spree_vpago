require 'faraday'

module Vpago
  class PaymentRedirectHandler
    include ActiveModel::Serialization

    attr_accessor :redirect_options, :error_message
    attr_reader :payment, :payment_method_type, :gateway_params, :action_url, :vapgo_checkout_service

    delegate      :id, :amount, :response_code, :number, :state,
                  :payment_method_id, :payment_method_name,
              to: :payment

    def initialize(payment:)
      @payment = payment
      @vapgo_checkout_service = payment.payment_method.vapgo_checkout_service.new(payment)
      @gateway_params = vapgo_checkout_service.gateway_params
      @action_url = vapgo_checkout_service.action_url
    end

    def process
      validate_payment
      check_and_process_payment

      self
    end

    def check_and_process_payment
      if payment_method.type_payway_v2?
        process_aba_v2_gateway
      elsif payment_method.type_payway?
        process_aba_gateway
      elsif payment_method.type_wingsdk?
        process_wing_gateway
      elsif payment_method.type_acleda?
        process_acleda_gateway
      elsif payment_method.type_acleda_mobile?
        process_acleda_mobile
      end
    end

    def process_acleda_gateway
      data = {
        href: "#{ENV['DEFAULT_URL_HOST']}/acleda_redirects?payment_number=#{@payment.number}"
      }

      @redirect_options = data
    end

    def process_acleda_mobile
      service = Vpago::AcledaMobile::Checkout.new(@payment)
      service.call

      @redirect_options = service.results
    end

    def process_aba_v2_gateway
      payment_option = @payment.payment_method.preferences[:payment_option]

      @payment.process!

      if payment_option == 'abapay'
        process_abapay_v2_deeplink
      else
        # construct web url for render web view.
        # same implementation for alipay, wechat, cards, abapay_khqr.

        # - for abapay_khqr: in web view, it renders QR then request to open intent://ababank.com?... for app to open ABA app.
        # - for others: it only renders QR
        process_payway_v2_card
      end
    end

    def process_payway_v2_card
      ## TO DO: generate redirect url
      data = {
        href: "#{ENV['DEFAULT_URL_HOST']}/payway_v2_card_popups?payment_number=#{@payment.number}"
      }

      @redirect_options = data
    end

    def process_abapay_v2_deeplink
      response = send_process_payway_v2_payment

      if response.status == 200
        json_response = JSON.parse(response.body)

        if json_response["status"]["code"] == "00"
          @redirect_options = json_response
        else
          @error_message = json_response["description"]
        end
      end
    end

    def send_process_payway_v2_payment
      options = {
        app_checkout: true
      }

      abapay_payment = ::Vpago::PaywayV2::Checkout.new(@payment, options)
      gateway_params = abapay_payment.gateway_params

      conn = Faraday::Connection.new do |faraday|
        faraday.request  :url_encoded
      end

      conn.post(abapay_payment.checkout_url, gateway_params) do |request|
        request.headers["Referer"] = ENV['DEFAULT_URL_HOST']
      end
    end

    def process_aba_gateway
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

    def process_wing_gateway
      data = {
        href: "#{ENV['DEFAULT_URL_HOST']}/wing_redirects?payment_number=#{@payment.number}"
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
      options = {
        app_checkout: true
      }

      abapay_payment = ::Vpago::Payway::Checkout.new(@payment, options)
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
      raise ActiveRecord::RecordNotFound if !payment_valid || !payment_method.vpago_payment?

      true
    end

    def payment_method
      @payment.payment_method
    end

    def payment_method_type
      payment_method.type
    end

    def payment_valid
      !::Spree::Payment::INVALID_STATES.include?(@payment.state)
    end
  end
end
