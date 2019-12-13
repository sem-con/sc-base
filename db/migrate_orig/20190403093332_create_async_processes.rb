class CreateAsyncProcesses < ActiveRecord::Migration[5.1]
  def change
    create_table :async_processes do |t|
      t.string :rid
      t.text :request
      t.integer :status

      t.timestamps
    end
  end
end
