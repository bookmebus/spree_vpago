class AddRunByToSpreePromotionActions < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_promotion_actions, :run_by, :integer, null: false, default: 0, if_not_exists: true
  end
end
