module Vpago
  module StoreDecorator
    def self.prepended(base)
      # override
      base.has_many :payment_methods, -> { where(vendor_id: nil) },
                    through: :store_payment_methods,
                    class_name: 'Spree::PaymentMethod'

      base.has_many :payment_methods_including_vendor,
                    through: :store_payment_methods,
                    class_name: 'Spree::PaymentMethod',
                    source: :payment_method
    end
  end
end

Spree::Store.prepend(Vpago::StoreDecorator) unless Spree::Store.included_modules.include?(Vpago::StoreDecorator)
