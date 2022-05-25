class AddOidcToOauthApplications < ActiveRecord::Migration[5.2]
  def change
    add_column :oauth_applications, :oidc_identifier, :string
    add_column :oauth_applications, :oidc_secret, :string
    add_column :oauth_applications, :oidc_token_endpoint, :string
  end
end
