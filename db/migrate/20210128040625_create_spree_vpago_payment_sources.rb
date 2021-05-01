class CreateSpreeVpagoPaymentSources < ActiveRecord::Migration[4.2]
  def change
    create_table :spree_vpago_payment_sources do |t|
      t.integer :user_id
      t.string :payment_option
      t.integer :payment_method_id
      t.string :transaction_id
      t.string :payment_status
      t.string :payment_description

      t.timestamps
    end
  end
end
