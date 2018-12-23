class AddUidToSemantics < ActiveRecord::Migration[5.1]
  def change
    add_column :semantics, :uid, :string
  end
end
