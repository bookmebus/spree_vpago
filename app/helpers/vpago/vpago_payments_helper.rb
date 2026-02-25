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
      user_agent = request.user_agent.to_s.downcase

      if user_agent.include?('telegram')
        'tg://'
      elsif user_agent.include?('fban') || user_agent.include?('facebook')
        'fb://'
      elsif user_agent.include?('messenger')
        'fb-messenger://'
      end
    end
  end
end
