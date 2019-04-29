class ApiController < ApplicationController
	before_action :authentication_check

	private

	def authentication_check
		if !(ENV["AUTH"].to_s == "" || ENV["AUTH"].to_s.downcase == "false")
			if ENV["AUTH"].to_s.downcase == "billing" && (controller_name == "stores" || controller_name == "payments")
				case action_name
				when "index", "plain", "full", "provision", "buy"
					puts "===SPECIAL HANDLING FOR COMMERCIAL DATA==="
					true
				else
					if action_name != "active" && action_name != "init"
						if action_name == "write"
							doorkeeper_authorize! :write, :admin
						else
							doorkeeper_authorize! :read, :write, :admin
						end
					end
				end
			else
				if action_name != "active" && action_name != "init"
					if action_name == "write"
						doorkeeper_authorize! :write, :admin
					else
						doorkeeper_authorize! :read, :write, :admin
					end
				end
			end
		end
	end
end