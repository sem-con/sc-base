class AddBuyerInfoToBillings < ActiveRecord::Migration[5.1]
  def change
    add_column :billings, :buyer_info, :text
  end
end
