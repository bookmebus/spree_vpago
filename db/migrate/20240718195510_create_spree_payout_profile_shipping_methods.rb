class CreateSpreePayoutProfileShippingMethods < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_payout_profile_shipping_methods, if_not_exists: true do |t|
      t.references :payout_profile, foreign_key: { to_table: :spree_payout_profiles },
                                    index: { name: 'index_payout_profile_shipping_methods_on_payout_profile_id' }

      t.references :shipping_method, foreign_key: { to_table: :spree_shipping_methods },
                                     index: { name: 'index_payout_profile_shipping_methods_on_shipping_method_id' }

      t.boolean :optional, null: false, default: false

      t.timestamps
    end
  end
end
