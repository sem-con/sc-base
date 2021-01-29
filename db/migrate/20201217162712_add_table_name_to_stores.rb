class AddTableNameToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :table_name, :string
    add_index :stores, :table_name
  end
end
