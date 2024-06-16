class CreateSpreePayouts < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_payouts, if_not_exists: true do |t|
      t.references :payout_profile, foreign_key: { to_table: :spree_payout_profiles }
      t.references :line_item, foreign_key: { to_table: :spree_line_items }
      t.references :payment, foreign_key: { to_table: :spree_payments }

      t.integer :state, default: 0, null: false

      t.decimal :amount, precision: 10, scale: 2, default: "0.0", null: false
      t.decimal :commission_rate, default: "0.0", null: false
      t.decimal :commission_amount, precision: 10, scale: 2, default: "0.0", null: false
      t.decimal :pre_commission_amount, precision: 10, scale: 2, default: "0.0", null: false
      t.decimal :outstanding_amount, precision: 10, scale: 2, default: "0.0", null: false

      t.timestamps
    end
  end
end
