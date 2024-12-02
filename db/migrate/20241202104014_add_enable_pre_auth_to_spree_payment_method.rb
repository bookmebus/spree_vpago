class AddEnablePreAuthToSpreePaymentMethod < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_payment_methods, :enable_pre_auth, :boolean, default: false, if_not_exists: true
  end
end
