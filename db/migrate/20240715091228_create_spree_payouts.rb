class CreateSpreePayouts < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_payouts, if_not_exists: true do |t|
      t.references :payout_profile, foreign_key: { to_table: :spree_payout_profiles }
      t.references :payoutable, polymorphic: true, index: true
      t.references :payment, foreign_key: { to_table: :spree_payments }

      t.integer :state, default: 0, null: false
      t.boolean :default, default: false, null: false

      t.decimal :outstanding_amount, precision: 10, scale: 2
      t.decimal :amount, precision: 10, scale: 2, default: '0.0', null: false

      if t.respond_to? :jsonb
        t.jsonb :public_metadata
        t.jsonb :private_metadata
      else
        t.json :public_metadata
        t.json :private_metadata
      end

      t.timestamps
    end
  end
end
