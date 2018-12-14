module Api
    module V1
        class InfosController < ApiController
            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def index
                render json: {"records": Store.count}.to_json, 
                       status: 200
            end
        end
    end
end