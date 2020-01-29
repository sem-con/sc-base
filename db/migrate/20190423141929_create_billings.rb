class CreateBillings < ActiveRecord::Migration[5.1]
  def change
    create_table :billings do |t|
      t.string :uid
      t.string :buyer
      t.string :buyer_pubkey_id
      t.string :seller
      t.string :seller_pubkey_id
      t.text :request
      t.text :usage_policy
      t.string :payment_method
      t.text :buyer_signature
      t.text :seller_signature
      t.timestamp :offer_timestamp
      t.float :offer_price
      t.string :payment_address
      t.timestamp :payment_timestamp
      t.float :payment_price

      t.timestamps
    end
  end
end
