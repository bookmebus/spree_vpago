class AddHandleByToSpreeShippingMethod < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_shipping_methods, :handle_by, :integer, null: false, default: 0, if_not_exists: true
  end
end
