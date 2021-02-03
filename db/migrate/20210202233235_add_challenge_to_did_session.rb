class AddChallengeToDidSession < ActiveRecord::Migration[5.2]
  def change
    add_column :did_sessions, :challenge, :string
  end
end
