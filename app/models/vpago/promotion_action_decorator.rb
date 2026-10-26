module Vpago
  module PromotionActionDecorator
    def self.prepended(base)
      base.enum run_by: { store: 0, vendor: 1 }, _prefix: true
    end
  end
end

Spree::PromotionAction.prepend(Vpago::PromotionActionDecorator) unless Spree::PromotionAction.included_modules.include?(Vpago::PromotionActionDecorator)
