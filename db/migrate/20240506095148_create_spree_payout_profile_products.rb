class CreateSpreePayoutProfileProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_payout_profile_products, if_not_exists: true do |t|
      t.references :payout_profile, foreign_key: { to_table: :spree_payout_profiles }
      t.references :product, foreign_key: { to_table: :spree_products }

      t.timestamps
    end
  end
end
