class CreateProvenances < ActiveRecord::Migration[5.1]
  def change
    create_table :provenances do |t|
      t.text :prov

      t.timestamps
    end
  end
end
