module Vpago
  module OrderDecorator
    extend Spree::DisplayMoney
    money_methods :order_adjustment_total, :shipping_discount

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

      if !confirmation_delivered? && (paid? || authorized?)
        deliver_order_confirmation_email
      end

      consider_risk
    end

    def required_payway_payout?
      line_items.any?(&:required_payway_payout?)
    end

    def line_items_count
      line_items.size
    end

    # override
    def available_payment_methods(store = nil)
      payment_methods = collect_payment_methods(store)

      @available_payment_methods ||= if required_payway_payout?
        payment_methods.select { |payment| payment.type_payway_v2? }
      else
        payment_methods
      end
    end

    def send_confirmation_email!
      if !confirmation_delivered? && (paid? || authorized?)
        deliver_order_confirmation_email
      end
    end

    def successful_payment
      paid? || payments.any? {|p| p.after_pay_method? && p.authorized?}
    end

    alias paid_or_authorized? successful_payment

    def authorized?
      payments.last.authorized?
    end

    def order_adjustment_total
      adjustments.eligible.sum(:amount)
    end

    def has_order_adjustments?
      order_adjustment_total.abs > 0
    end
  end
end

Spree::Order.prepend(Vpago::OrderDecorator)
