class CreateDidSessions < ActiveRecord::Migration[5.2]
  def change
    create_table :did_sessions do |t|
      t.string :session
      t.string :oauth_application_id

      t.timestamps
    end
  end
end
