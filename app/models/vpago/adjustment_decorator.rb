module Vpago
  module AdjustmentDecorator
    def self.prepended(base)
      base.enum handle_by: { store: 0, vendor: 1 }, _prefix: true

      base.scope :handle_by_vendor, -> { eligible.where(handle_by: :vendor) }
      base.scope :handle_by_store, -> { eligible.where(handle_by: :store) }

      base.before_save :set_handle_by

      def base.total
        sum(:amount) || 0
      end
    end

    private

    def set_handle_by
      if source.is_a?(::Spree::PromotionAction)
        self.handle_by = source.run_by
      elsif source.is_a?(::Spree::TaxRate)
        self.handle_by = source.tax_category.collect_by
      end
    end
  end
end

Spree::Adjustment.prepend(Vpago::AdjustmentDecorator) unless Spree::Adjustment.included_modules.include?(Vpago::AdjustmentDecorator)
