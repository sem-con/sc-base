module Api
    module V1
        class StoresController < ApiController
            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def index
                retVal = []
                Store.pluck(:item).each { |item| retVal << JSON(item) }
                render json: retVal.to_json, 
                       status: 200
            end

            def create
                if Semantic.count == 0
                    render json: { "error": "semantic definition not set yet"},
                           status: 412
                    return
                end

                # puts "Headers (Email): " + request.headers["Email"]
                # puts "Params: " + JSON.parse(params.to_json)['_json'].to_s
                input = {
                    "@context": JSON.parse(params["@context"].to_json),
                    "@graph": JSON.parse(params["@graph"].to_json) }.stringify_keys

                # combine with semantic validation JSON
                combined_data = {
                    "content": input,
                    "constraints": JSON.parse(Semantic.first.validation)
                }

                # check if content is valid
                data_validation_url = "https://semantic.ownyourdata.eu/api/validate/content"
                response = HTTParty.post(data_validation_url, 
                    headers: { 'Content-Type' => 'application/json' },
                    body: combined_data.to_json )
                if response.code.to_s == "200"
                    Store.new(item: input.to_s.gsub('=>', ':')).save
                    render plain: "", 
                           status: 200
                else
                    render json: { "error": "data does not pass semantic validation"},
                           status: 422
                    return
                end
            end
        end
    end
end