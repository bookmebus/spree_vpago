class CreateSpreePayoutProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_payout_profiles, if_not_exists: true do |t|
      t.string :type
      t.string :name
      t.string :bank_account_number

      t.boolean :active, default: false
      t.boolean :default, default: false

      t.text :preferences
      t.jsonb :response_data, default: {}
      t.references :vendor, foreign_key: { to_table: :spree_vendors }

      t.timestamp :verified_at
      t.timestamp :deleted_at
      t.timestamps
      
      t.index [:type, :bank_account_number, :vendor_id], name: :index_spree_payout_profiles_on_type_and_bank_and_vendor
    end
  end
end
