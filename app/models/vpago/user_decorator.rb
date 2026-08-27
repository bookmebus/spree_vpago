module Vpago
  module UserDecorator
    def self.prepended(base)
      base.has_one :linked_account, dependent: :destroy, class_name: 'Spree::LinkedAccount'
    end
  end
end

Spree::Product.prepend(Vpago::UserDecorator)
