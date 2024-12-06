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

    # Make sure the order confirmation is delivered when the order has been paid for.
    def finalize!
      # lock all adjustments (coupon promotions, etc.)
      all_adjustments.each(&:close)

      # update payment and shipment(s) states, and save
      updater.update_payment_state

      shipments.each do |shipment|
        shipment.update!(self)
        shipment.finalize! if paid? || authorized?
      end

      updater.update_shipment_state
      save!
      updater.run_hooks

      touch :completed_at

      deliver_order_confirmation_email if !confirmation_delivered? && (paid? || authorized?)

      consider_risk
    end

    def required_payway_payout?
      line_items.any?(&:required_payway_payout?) || shipments.any?(&:required_payway_payout?)
    end

    # override
    def available_payment_methods(store = nil)
      payment_methods = if vendor_payment_methods.any?
                          vendor_payment_methods.active
                        else
                          collect_payment_methods(store)
                        end

      payment_methods = if required_payway_payout?
                          payment_methods.select(&:type_payway_v2?)
                        else
                          payment_methods
                        end

      @available_payment_methods ||= payment_methods.select do |payment_method|
        payment_method_allowed?(payment_method)
      end
    end

    def payment_method_allowed?(payment_method)
      return true unless payment_method_set_allow_role?(payment_method)
      return false if user.nil? && payment_method_set_allow_role?(payment_method)

      user.role_users.any? do |role_user|
        bit_field = Vpago::PaymentMethodDecorator::BIT_FIELDS[role_user.role.name.to_sym]
        bit_field && (payment_method.preferred_allow_role & bit_field) != 0
      end
    end

    def payment_method_set_allow_role?(payment_method)
      payment_method.preferred_allow_role != 0
    end

    def line_items_count
      line_items.size
    end

    def generate_line_items_total_metadata
      line_items.each(&:update_total_metadata)
    end

    def send_confirmation_email!
      return unless !confirmation_delivered? && (paid? || authorized?)

      deliver_order_confirmation_email
    end

    def successful_payment
      paid? || payments.any? { |p| p.after_pay_method? && p.authorized? }
    end

    alias paid_or_authorized? successful_payment

    def authorized?
      payments.last.authorized?
    end

    def order_adjustment_total
      adjustments.eligible.sum(:amount)
    end
  end
end

if Spree::Order.included_modules.exclude?(Vpago::OrderDecorator)
  Spree::Order.register_update_hook(:generate_line_items_total_metadata)
  Spree::Order.prepend(Vpago::OrderDecorator)
end
