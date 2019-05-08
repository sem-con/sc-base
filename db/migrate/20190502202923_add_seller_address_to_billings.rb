class AddSellerAddressToBillings < ActiveRecord::Migration[5.1]
  def change
    add_column :billings, :buyer_address, :string
  end
end
