class AddStoreIdToAsyncProcesses < ActiveRecord::Migration[5.1]
  def change
    add_column :async_processes, :store_id, :integer
  end
end
