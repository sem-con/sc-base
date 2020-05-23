class AddReceiptToLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :logs, :receipt, :string
  end
end
