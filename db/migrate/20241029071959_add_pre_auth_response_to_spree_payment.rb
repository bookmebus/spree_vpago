class AddPreAuthResponseToSpreePayment < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_payments, :pre_auth_response, :jsonb, default: {}, if_not_exists: true
  end
end
