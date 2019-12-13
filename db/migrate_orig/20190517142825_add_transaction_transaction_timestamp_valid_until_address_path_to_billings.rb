class AddTransactionTransactionTimestampValidUntilAddressPathToBillings < ActiveRecord::Migration[5.1]
  def change
    add_column :billings, :transaction, :string
    add_column :billings, :transaction_timestamp, :string
    add_column :billings, :valid_until, :datetime
    add_column :billings, :address_path, :string
  end
end
