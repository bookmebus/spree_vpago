module Vpago
  module PromotionActionDecorator
    def self.prepended(base)
      base.enum run_by: { unspecified: 0, store: 1, vendor: 2 }, _prefix: true
    end
  end
end

unless Spree::PromotionAction.included_modules.include?(Vpago::PromotionActionDecorator)
  Spree::PromotionAction.prepend(Vpago::PromotionActionDecorator)
end
