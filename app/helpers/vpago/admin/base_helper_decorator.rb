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
          cheque
          payway_cards
          wingpay
        ]
      end

      def preference_field_for(form, field, options)
        case field
        when 'preferred_acleda_type'
          return form.select(:preferred_acleda_type, form.object.class::TYPES, {}, class: 'fullwidth select2')
        when 'preferred_acleda_payment_card'
          return form.select(:preferred_acleda_payment_card, acleda_payment_card_options, {}, class: 'fullwidth select2')
        when 'preferred_icon_name'
          return form.select(:preferred_icon_name, available_payment_icons, {}, class: 'fullwidth select2')
        end

        super
      end
    end
  end
end

Spree::Admin::BaseHelper.prepend(Vpago::Admin::BaseHelperDecorator)
