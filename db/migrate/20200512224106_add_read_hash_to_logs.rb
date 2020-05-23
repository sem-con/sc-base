class AddReadHashToLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :logs, :read_hash, :string
  end
end
