class AddStartAndEndTimeToProvenances < ActiveRecord::Migration[5.1]
  def change
    add_column :provenances, :startTime, :timestamp
    add_column :provenances, :endTime, :timestamp
  end
end
