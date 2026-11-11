class AddOptionalSperePayoutProfileProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_payout_profile_products, :optional, :boolean, null: false, default: false, if_not_exists: true
  end
end
