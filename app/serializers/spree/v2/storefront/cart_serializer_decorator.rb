module Spree
  module V2
    module Storefront
      module PaymentMethodSerializerDecorator
        def self.prepended(base)
          base.attribute :payment_option do |payment|
            payment.preferences.blank? ? nil : payment.preferences[:payment_option]
          end
        end
      end
    end
  end
end

Spree::V2::Storefront::PaymentMethodSerializer.prepend(Spree::V2::Storefront::PaymentMethodSerializerDecorator)
