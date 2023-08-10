module Vpago
  class PaywayReturnOptionsBuilder
    attr_reader :params

    def initialize(params:)
      @params = params
    end

    def options
      if merchant_profile_content_type == 'html'
        html_params
      elsif merchant_profile_content_type == 'json'
        json_params
      end
    end

    def payment
      @payment ||= Spree::Payment.find_by(number: tran_id)
    end

    def tran_id
      @tran_id ||= options[:tran_id]
    end

    def json_params
      { :tran_id => params[:tran_id] }
    end

    def html_params
      payload = JSON.parse(params[:response])
      { :tran_id => payload["tran_id"] }
    end

    def merchant_profile_content_type
      ENV["PAYWAY_MERCHANT_PROFILE_CONTENT_TYPE"].presence || 'html'
    end
  end
end