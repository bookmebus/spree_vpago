class CreateSpreePayoutProfilePayments < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_payout_profile_payments, if_not_exists: true do |t|
      t.decimal :amount, precision: 10, scale: 2, default: "0.0"

      t.references :payout_profile, foreign_key: { to_table: :spree_payout_profiles }
      t.references :payment, foreign_key: { to_table: :spree_payments }

      t.timestamps
    end
  end
end
