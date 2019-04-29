class AddFileListToAsyncProcesses < ActiveRecord::Migration[5.1]
  def change
    add_column :async_processes, :file_list, :text
  end
end
