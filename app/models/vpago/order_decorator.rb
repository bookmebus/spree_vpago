module Vpago
  module OrderDecorator
    extend Spree::DisplayMoney
    money_methods :order_adjustment_total, :shipping_discount

    def self.prepended(base)
      base.has_many :payouts, class_name: 'Spree::Payout', through: :payments
      base.has_many :vendor_payment_methods, -> { unscope(:order).distinct },
                    class_name: 'Spree::PaymentMethod',
                    through: :line_items

      base.state_machine.before_transition from: :cart, do: :ensure_valid_vendor_payment_methods
      base.state_machine.after_transition to: :complete, do: :generate_line_items_total_metadata
    end

    # override
    def process_payments!
      super if insufficient_processed_payment?

      # Prevent from reaching :complete state if payment is insufficient
      errors.add(:base, Spree.t(:insufficient_payment_amount_to_cover_the_total)) if insufficient_processed_payment?
    end

    def insufficient_processed_payment?
      processed_payment_total < total
    end

    def processed_payment_total
      payment_total + pending_payments.sum(:amount)
    end

    def ensure_valid_vendor_payment_methods
      return if line_items_from_same_vendor?
      return unless vendor_payment_methods.any?

      errors.add(:line_items, 'some_payment_methods_cant_be_used_across_vendors')

      false
    end

    def line_items_from_same_vendor?
      line_items.joins(:variant).pluck('spree_variants.vendor_id').uniq.size == 1
    end

    def required_payway_payout?
      line_items.any?(&:required_payway_payout?) || shipments.any?(&:required_payway_payout?)
    end

    # override
    def available_payment_methods(store = nil)
      payment_methods = if respond_to?(:tenant) && tenant.present?
                          tenant_payment_methods
                        elsif vendor_payment_methods.any?
                          vendor_payment_methods
                        else
                          collect_payment_methods(store)
                        end

      @available_payment_methods ||= if required_payway_payout?
                                       payment_methods.select(&:type_payway_v2?)
                                     else
                                       payment_methods
                                     end
    end

    def tenant_payment_methods
      tenant.tenant_payment_methods
    end

    def line_items_count
      line_items.size
    end

    def generate_line_items_total_metadata
      line_items.each(&:update_total_metadata)
    end

    def order_adjustment_total
      adjustments.eligible.sum(:amount)
    end

    # override this method if you want flexibility
    # for example, host per payment method or tenant
    def payment_host
      ENV.fetch('DEFAULT_URL_HOST')
    end
  end
end

Spree::Order.prepend(Vpago::OrderDecorator) if Spree::Order.included_modules.exclude?(Vpago::OrderDecorator)
