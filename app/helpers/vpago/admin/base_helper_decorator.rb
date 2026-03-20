module Vpago
  module Admin
    module BaseHelperDecorator
      def acleda_payment_card_options
        { '0 - XPAY': 0, '1 - Visa, Master Card, etc.': 1 }
      end

      # frontend should implement these in UI
      def available_payment_icons
        %w[
          payway_abapay_khqr
          payway_abapay
          payway_alipay
          payway_wechat
          acleda
          acleda_khqr
          acleda_cards
          cheque
          payway_cards
          wingpay
          vattanac_mini_app
          vattanac
          true_money
        ]
      end

      def available_vattanac_payment_options
        %w[khqr deeplink all]
      end

      def preference_field_for(form, field, options)
        case field
        when 'preferred_acleda_type'
          return form.select(:preferred_acleda_type, form.object.class::TYPES, {}, class: 'fullwidth select2')
        when 'preferred_acleda_payment_card'
          return form.select(:preferred_acleda_payment_card, acleda_payment_card_options, {},
                             class: 'fullwidth select2')
        when 'preferred_icon_name'
          return form.select(:preferred_icon_name, available_payment_icons, {}, class: 'fullwidth select2')
        when 'preferred_payment_option'
          return form.select(:preferred_payment_option, Spree::Gateway::PaywayV2::PAYMENT_OPTIONS, {}, class: 'fullwidth select2')
        when 'preferred_abapay_khqr_deeplink_option'
          return ''.html_safe unless form.object.abapay_khqr_deeplink?

          return form.select(:preferred_abapay_khqr_deeplink_option, Spree::Gateway::PaywayV2::ABAPAY_KHQR_DEEPLINK_OPTIONS, {}, class: 'fullwidth select2')
        when 'preferred_vattanac_payment_option'
          return form.select(:preferred_vattanac_payment_option, available_vattanac_payment_options, {}, class: 'fullwidth select2')
        end
        super
      end
    end
  end
end

Spree::Admin::BaseHelper.prepend(Vpago::Admin::BaseHelperDecorator)
