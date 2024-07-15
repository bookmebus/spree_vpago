class CreateSpreePayouts < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_payouts do |t|
      t.references :payout_profile, foreign_key: { to_table: :spree_payout_profiles }
      t.references :line_item, foreign_key: { to_table: :spree_line_items }
      t.references :payment, foreign_key: { to_table: :spree_payments }

      t.integer :state, default: 0, null: false
      t.boolean :default, default: false, null: false

      t.decimal :outstanding_amount, precision: 10, scale: 2
      t.decimal :amount, precision: 10, scale: 2, default: '0.0', null: false

      t.timestamps
    end
  end
end
