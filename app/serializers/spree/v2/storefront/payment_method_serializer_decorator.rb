module Spree
  module V2
    module Storefront
      module PaymentMethodSerializerDecorator
        def self.prepended(base)
          base.attribute :payment_option do |payment_method|
            payment_method.preferences.blank? ? nil : payment_method.preferences[:payment_option]
          end
        end
      end
    end
  end
end

Spree::V2::Storefront::PaymentMethodSerializer.prepend(Spree::V2::Storefront::PaymentMethodSerializerDecorator)
