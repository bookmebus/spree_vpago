module Vpago
  module TaxCategoryDecorator
    def self.prepended(base)
      base.enum collect_by: { unspecified: 0, store: 1, vendor: 2 }, _prefix: true
    end
  end
end

unless Spree::TaxCategory.included_modules.include?(Vpago::TaxCategoryDecorator)
  Spree::TaxCategory.prepend(Vpago::TaxCategoryDecorator)
end
