class ChangeTransactionInBillings < ActiveRecord::Migration[5.1]
  def change
    rename_column :billings, :transaction, :transaction_hash
  end
end
