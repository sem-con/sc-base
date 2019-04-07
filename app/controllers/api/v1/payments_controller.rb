module Api
    module V1
        class PaymentsController < ApiController
            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def buy
                retVal = {}

                render json: retVal.to_json, 
                       status: 200
            end

            def paid
                retVal = {}

                render json: retVal.to_json, 
                       status: 200
            end
        end
    end
end