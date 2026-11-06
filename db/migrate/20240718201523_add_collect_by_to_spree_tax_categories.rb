class AddCollectByToSpreeTaxCategories < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_tax_categories, :collect_by, :integer, null: false, default: 0, if_not_exists: true
  end
end
