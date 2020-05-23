class AddScopeToProvenances < ActiveRecord::Migration[5.2]
  def change
    add_column :provenances, :scope, :text
  end
end
