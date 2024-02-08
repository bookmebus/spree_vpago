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
        end
      end
    end
  end
end

Spree::V2::Storefront::PaymentMethodSerializer.prepend(Spree::V2::Storefront::PaymentMethodSerializerDecorator)
