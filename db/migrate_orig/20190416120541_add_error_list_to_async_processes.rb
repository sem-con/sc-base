class AddErrorListToAsyncProcesses < ActiveRecord::Migration[5.1]
  def change
    add_column :async_processes, :error_list, :text
  end
end
