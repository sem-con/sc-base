class ApiController < ApplicationController
	before_action :authentication_check

	private

	def authentication_check
		if ENV["AUTH"].to_s != "" && (action_name != "active" && action_name != "init")
			if action_name == "write"
				doorkeeper_authorize! :write, :admin
			else
				doorkeeper_authorize! :read, :write, :admin
			end
		end
	end
end