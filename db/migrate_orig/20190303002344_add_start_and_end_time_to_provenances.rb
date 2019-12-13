class AddStartAndEndTimeToProvenances < ActiveRecord::Migration[5.1]
  def change
    add_column :provenances, :startTime, :dateTime
    add_column :provenances, :endTime, :dateTime
  end
end
