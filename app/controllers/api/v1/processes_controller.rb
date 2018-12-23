module Api
    module V1
        class ProcessesController < ApiController
            require 'securerandom'
            include ApplicationHelper

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def init
                uid = SecureRandom.hex(16)
                Semantic.new(uid: uid)
                createLog({
                    "type": "create",
                    "scope": ENV["IMAGE_NAME"].to_s + " (" + ENV["IMAGE_SHA256"].to_s + "): " + uid.to_s,
                    "request": "init.sh"}.to_json)

                render plain: "",
                       status: 200

            end
        end
    end
end

