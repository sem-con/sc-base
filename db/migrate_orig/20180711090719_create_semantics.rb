class CreateSemantics < ActiveRecord::Migration[5.1]
  def change
    create_table :semantics do |t|
      t.text :validation

      t.timestamps
    end
  end
end
