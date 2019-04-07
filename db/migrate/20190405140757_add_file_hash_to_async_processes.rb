class AddFileHashToAsyncProcesses < ActiveRecord::Migration[5.1]
  def change
    add_column :async_processes, :file_hash, :string
  end
end
