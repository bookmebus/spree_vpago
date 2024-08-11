module Vpago
  module VariantDecorator
    def self.prepended(base)
      base.belongs_to :vendor, class_name: 'Spree::Vendor'

      base.has_many :vendor_payment_methods, class_name: 'Spree::PaymentMethod',
                                             through: :vendor,
                                             source: :payment_methods
    end
  end
end

if Spree::Variant.included_modules.exclude?(Vpago::VariantDecorator)
  # spree_multi_vendor use :vendor method for assoication, we should use association (belongs_to :vendor) instead.
  #
  # problem with those methods is that it store value in memeory,
  # even we call variant.reload, the method value is no being reload.
  SpreeMultiVendor::Spree::VariantDecorator.remove_method :vendor
  SpreeMultiVendor::Spree::VariantDecorator.remove_method :vendor_id

  Spree::Variant.prepend(Vpago::VariantDecorator)
end
