class CreateWatermarks < ActiveRecord::Migration[5.1]
  def change
    create_table :watermarks do |t|
      t.integer :account_id
      t.string :fragment
      t.text :key

      t.timestamps
    end
  end
end
