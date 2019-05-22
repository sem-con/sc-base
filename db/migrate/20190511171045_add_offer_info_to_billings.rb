class AddOfferInfoToBillings < ActiveRecord::Migration[5.1]
  def change
    add_column :billings, :offer_info, :text
  end
end
