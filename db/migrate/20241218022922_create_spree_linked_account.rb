class CreateSpreeLinkedAccount < ActiveRecord::Migration[7.0]
  def change
    create_table :spree_linked_accounts, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: { to_table: :spree_users }
      t.jsonb :response, default: {}
      t.timestamps
    end
  end
end
