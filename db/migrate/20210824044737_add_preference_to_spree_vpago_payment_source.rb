class AddPreferenceToSpreeVpagoPaymentSource < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_vpago_payment_sources, :preferences, :text
  end
end
