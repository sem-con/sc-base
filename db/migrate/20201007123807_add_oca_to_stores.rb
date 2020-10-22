class AddOcaToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :dri, :string
    add_column :stores, :schema_dri, :string
    add_column :stores, :mime_type, :string
    add_index :stores, :dri
    add_index :stores, :schema_dri
  end
end
