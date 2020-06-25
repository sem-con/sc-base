class AddConfidentialToDoorkeeperApplication < ActiveRecord::Migration[5.1]
  def change
    add_column(
      :oauth_applications,
      :confidential,
      :boolean,
      null: false,
      default: false # maintaining backwards compatibility: require secrets
    )
  end
end
