module Api
    module V1
        class ProcessesController < ApiController
            require 'securerandom'
            include ApplicationHelper

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def active
                render json: { "active": true,
                               "auth": ENV["AUTH"].to_s != "",
                               "repos": false,
                               "watermark":  ENV["WATERMARK"].to_s != "",
                               "billing": ENV["AUTH"].to_s == "billing",
                               "scopes": ["admin", "write", "read"]
                             }.to_json,
                       status: 200
            end

            def init
                # clean up
                uid = SecureRandom.uuid
                if Semantic.count == 0
                    Semantic.create!(uid: uid)
                end

                request_sh = "run.sh"
                if params[:run].to_s == ""
                    request_sh = "init.sh"
                end

                if ENV["AUTH"].to_s != ""
                    if Doorkeeper::Application.count == 0
                        Doorkeeper::Application.create!({ 
                            name: 'master', 
                            redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                            scopes: 'admin write read'})
                    end
                    puts "APP_KEY: " + Doorkeeper::Application.first.uid.to_s
                    puts "APP_SECRET: " + Doorkeeper::Application.first.secret.to_s
                    request_sh += " (with authentication)"
                end

                if ENV["IMAGE_NAME"].to_s == ""
                    scope = uid.to_s
                else
                    scope = ENV["IMAGE_NAME"].to_s + " (" + ENV["IMAGE_SHA256"].to_s + "): " + uid.to_s
                end
                createLog({
                    "type": "create",
                    "scope": scope })

                render plain: "",
                       status: 200

            end
        end
    end
end

