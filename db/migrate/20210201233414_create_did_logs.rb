class CreateDidLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :did_logs do |t|
      t.text :item
      t.string :oyd_hash
      t.string :did
      t.integer :ts

      t.timestamps
    end
    add_index :did_logs, :oyd_hash, unique: true
    add_index :did_logs, :did
  end
end
