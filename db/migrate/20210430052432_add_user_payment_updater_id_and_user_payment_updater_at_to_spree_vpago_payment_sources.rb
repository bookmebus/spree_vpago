class AddUserPaymentUpdaterIdAndUserPaymentUpdaterAtToSpreeVpagoPaymentSources < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_vpago_payment_sources, :updated_by_user_id, :integer
    add_column :spree_vpago_payment_sources, :updated_by_user_at, :datetime
    add_column :spree_vpago_payment_sources, :updated_reason, :string
  end
end
