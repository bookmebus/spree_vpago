module Spree
  module V2
    module Storefront
      module PaymentSerializerDecorator
        def self.prepended(base)
          base.attributes :pre_auth_status, :checkout_url, :process_payment_url, :web_checkout_url
        end
      end
    end
  end
end

Spree::V2::Storefront::PaymentSerializer.prepend(Spree::V2::Storefront::PaymentSerializerDecorator)
