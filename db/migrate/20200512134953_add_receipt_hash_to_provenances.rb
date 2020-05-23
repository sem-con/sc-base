class AddReceiptHashToProvenances < ActiveRecord::Migration[5.2]
  def change
    add_column :provenances, :receipt_hash, :string
  end
end
