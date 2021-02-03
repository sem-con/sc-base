class AddQueryToOauthApplications < ActiveRecord::Migration[5.2]
  def change
    add_column :oauth_applications, :sc_query, :string
  end
end
