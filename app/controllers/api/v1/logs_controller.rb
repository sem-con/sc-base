module Api
    module V1
        class LogsController < ApiController
            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def index
                render json: Log.all.to_json, 
                       status: 200
            end
        end
    end
end