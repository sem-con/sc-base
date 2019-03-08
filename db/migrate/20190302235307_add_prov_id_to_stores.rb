class AddProvIdToStores < ActiveRecord::Migration[5.1]
  def change
    add_column :stores, :prov_id, :integer
  end
end
