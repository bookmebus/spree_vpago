class AddVendorReferenceToSpreePaymentMethods < ActiveRecord::Migration[7.0]
  def change
    add_reference :spree_payment_methods, :vendor,
                  index: true, foreign_key: { to_table: :spree_vendors },
                  if_not_exists: true
  end
end
