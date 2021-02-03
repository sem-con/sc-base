class CreateDids < ActiveRecord::Migration[5.2]
  def change
    create_table :dids do |t|
      t.string :did
      t.string :doc

      t.timestamps
    end
    add_index :dids, :did, unique: true
  end
end
