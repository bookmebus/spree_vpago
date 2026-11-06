module Vpago
  module TaxCategoryDecorator
    def self.prepended(base)
      base.enum collect_by: { store: 0, vendor: 1 }, _prefix: true
    end
  end
end

Spree::TaxCategory.prepend(Vpago::TaxCategoryDecorator) unless Spree::TaxCategory.included_modules.include?(Vpago::TaxCategoryDecorator)
