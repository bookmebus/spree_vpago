class AddTransactionResponseToSpreePayments < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_payments, :transaction_response, :jsonb, default: {}, if_not_exists: true
  end
end
