module Spree
  module V2
    module Storefront
      module CartSerializerDecorator
        def self.prepended(base)
          base.attribute :vpago_order_processing_url
        end
      end
    end
  end
end

# Both CartSerializer and OrderSerializer (which inherits from CartSerializer) need the decorator
# applied directly -- see SpreeCmCommissioner::V2::Storefront::CartSerializerDecorator for why
# (prepending to CartSerializer alone doesn't retroactively reach OrderSerializer).
Spree::V2::Storefront::OrderSerializer.prepend(Spree::V2::Storefront::CartSerializerDecorator) unless Spree::V2::Storefront::OrderSerializer.include?(Spree::V2::Storefront::CartSerializerDecorator)

Spree::V2::Storefront::CartSerializer.prepend(Spree::V2::Storefront::CartSerializerDecorator) unless Spree::V2::Storefront::CartSerializer.include?(Spree::V2::Storefront::CartSerializerDecorator)
