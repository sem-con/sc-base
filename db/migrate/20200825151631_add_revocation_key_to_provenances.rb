class AddRevocationKeyToProvenances < ActiveRecord::Migration[5.2]
  def change
    add_column :provenances, :revocation_key, :string
  end
end
