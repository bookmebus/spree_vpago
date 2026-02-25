module Vpago
  module VpagoPaymentsHelper
    def user_informer
      'firebase'
    end

    # eg. forms/spree/gateway/payway_v2
    def render_form
      render partial: "spree/vpago_payments/forms/#{@payment.payment_method.class.to_s.underscore}"
    end

    def render_payment_status_listener
      render partial: 'spree/vpago_payments/payment_status_listener'
    end

    # when return nil, each payment method should use their default URL.
    # eg. PayWayV2 will use the continue_success_url as deeplink back URL.
    def custom_return_deeplink_url
      if telegram_user_agent?
        'tg://'
      elsif facebook_user_agent?
        'fb://'
      elsif messenger_user_agent?
        'fb-messenger://'
      end
    end

    def mobile_user_agent?
      request.user_agent.to_s.downcase.match?(/android|iphone|ipad|ipod/)
    end

    def telegram_user_agent?
      request.user_agent.to_s.downcase.include?('telegram')
    end

    def facebook_user_agent?
      request.user_agent.to_s.downcase.include?('fban') || request.user_agent.to_s.downcase.include?('facebook')
    end

    def messenger_user_agent?
      request.user_agent.to_s.downcase.include?('messenger')
    end
  end
end
