class Spree::VpagoPaymentSource < Spree::Base
  # deprecated preferences from older versions kept for data integrity
  preference :wing_response, :hash
  preference :acleda_response, :hash
  preference :payway_v2_response, :hash

  belongs_to :payment_method
  belongs_to :user, class_name: 'Spree::User'
  belongs_to :updated_by_user, class_name: 'Spree::User'

  has_one :payment, as: :source

  # validates :updated_reason, presence: true, on: :update

  # Define possible available actions for vpago payments.
  # Then Spree::Payment#actions will select only those where can_<action>? returns true.
  #
  # These actions are triggered via: payment.send("#{action}!")
  # - [void] can be triggered void_transaction (the alias by spree is to avoid conflict with the transition method name)
  # - [open_checkout] is a view action and is handled manually in gems/spree_vpago/app/overrides/spree/admin/payments/_list/actions.html.erb.deface
  # - [process] [capture] [void] [cancel] are built-in methods in the Spree::Payment model.
  #
  # Usages:
  # See fire request method in gems/spree_backend/app/controllers/spree/admin/payments_controller.rb
  # See jobs in gems/spree_vpago/app/jobs/vpago which are triggered by processor jobs.
  #
  # override
  def actions
    %w[open_checkout process capture void cancel]
  end

  def can_open_checkout?(payment)
    payment.checkout?
  end

  def can_process?(payment)
    return false if payment.completed? || payment.pending?

    payment.processing? || payment.checkout? || payment.send(:has_invalid_state?)
  end

  # The flow is as follows: payment authorized -> order completed -> capture the amount -> end.
  def can_capture?(payment)
    # Capture action should be triggered when the order is completed/secured for the user.
    # Otherwise, we don't need to capture the payment as the order is not completed.
    return false unless payment.order.completed?

    # Most likely the payment is already captured, so we don't need to capture it again.
    return false if payment.completed?

    payment.pending?
  end

  # Spree has different refund logic, called credit. We use cancel as refund for now, but only for Vattanac/True Money.
  # In the future, we can adopt Spree's credit logic instead of cancel if needed.
  #
  # The flow is as follows: payment paid -> order fails -> cancel (refund) -> end.
  def can_cancel?(payment)
    return false unless payment.vattanac_mini_app_payment? || payment.true_money_payment?

    # Cancel action is triggered when an order fails to complete.
    # So if the order somehow completes, we do not need to cancel the payment.
    return false if payment.order.completed?

    # Most likely the payment is already canceled/voided, so we don't need to cancel it again.
    return false if payment.void?

    payment.completed?
  end

  # The flow is as follows: payment authorized -> order failed -> void (release held payment) -> end.
  def can_void?(payment)
    payment.pending?
  end
end
