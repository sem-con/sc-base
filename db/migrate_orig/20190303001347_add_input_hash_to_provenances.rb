class AddInputHashToProvenances < ActiveRecord::Migration[5.1]
  def change
    add_column :provenances, :input_hash, :string
  end
end
