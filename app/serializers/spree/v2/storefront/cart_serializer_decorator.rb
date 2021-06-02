module Spree
  module V2
    module Storefront
      module CartSerializerDecorator
        def self.prepended(base)
          base.attribute :last_payment do |order|
            order.payments.last if order.payments.present?
          end
        end
      end
    end
  end
end

Spree::V2::Storefront::CartSerializer.prepend(Spree::V2::Storefront::CartSerializerDecorator)
