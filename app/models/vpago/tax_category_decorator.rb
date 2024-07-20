module Vpago
  module TaxCategoryDecorator
    def self.prepended(base)
      base.enum collect_by: { store: 0, vendor: 1 }, _prefix: true
    end
  end
end

unless Spree::TaxCategory.included_modules.include?(Vpago::TaxCategoryDecorator)
  Spree::TaxCategory.prepend(Vpago::TaxCategoryDecorator)
end
