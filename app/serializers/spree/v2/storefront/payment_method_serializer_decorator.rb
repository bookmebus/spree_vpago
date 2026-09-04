module Spree
  module V2
    module Storefront
      module PaymentMethodSerializerDecorator
        def self.prepended(base)
          base.attribute :icon_name do |payment_method|
            return nil if payment_method.preferences.blank?
  
            payment_method.preferences[:icon_name]
          end

          base.attribute :payment_option do |payment_method|
            pref = payment_method.preferences

            pref.blank? || pref[:payment_option].blank? ? payment_method.method_type : pref[:payment_option]
          end

          # Overried the payment method type to show all payment methods as one list on App.
          # Controlled by ENV["PAYMENT_METHOD_VIEW"] = "split" | "join" (default: "join").
          base.attribute :type do |payment_method|
            ENV.fetch('PAYMENT_METHOD_VIEW', 'join') == 'split' ? payment_method.type : 'payment_method'
          end
        end
      end
    end
  end
end

Spree::V2::Storefront::PaymentMethodSerializer.prepend(Spree::V2::Storefront::PaymentMethodSerializerDecorator)
