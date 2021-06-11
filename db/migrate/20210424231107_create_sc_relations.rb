class CreateScRelations < ActiveRecord::Migration[5.2]
  def change
    create_table :sc_relations do |t|
      t.integer :source_id
      t.integer :target_id

      t.timestamps
    end
    add_index :sc_relations, :source_id
    add_index :sc_relations, :target_id
  end
end
