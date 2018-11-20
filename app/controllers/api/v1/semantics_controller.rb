module Api
    module V1
        class SemanticsController < ApiController
            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def valid_json?(json)
                JSON.parse(json)
                return true
            rescue
                return false
            end

            def show
                if Semantic.count == 0
                    render json: {},
                           status: 200
                else
                    render json: Semantic.first.validation, 
                           status: 200
                end
            end

            def show_info
                if Semantic.count == 0
                    render json: {},
                           status: 200
                else
                    info = JSON.parse(Semantic.first.validation)["@graph"].first
                    render json: { "name": info["sh:name"], 
                                   "description": info["sh:description"]},
                           status: 200
                end
            end

            def show_example
                if Semantic.count == 0
                    render json: {},
                           status: 200
                else
                    info = JSON.parse(Semantic.first.validation)["@graph"].first
                    render plain: info["sc:example"],
                           status: 200
                end
            end             

            def create
                input = params.to_json
                if valid_json?(input)
                    if Semantic.count == 0
                        input = JSON.parse(input).except("format", "controller", "action", "semantic").to_s.gsub('=>', ':')

                        # check if input is valid
                        shacl_validation_url = "https://semantic.ownyourdata.eu/api/validate/shacl"
                        response = HTTParty.post(shacl_validation_url, body: input )
                        if response.code.to_s == "200"
                            Semantic.new(validation: input).save
                            render plain: "",
                                   status: 200
                        else
                            render json: { "error": "input is not a valid Shacl constraint"},
                                   status: 422
                            return
                        end
                    else
                        render json: { "error": "validation already set"},
                               status: 409
                    end
                else
                    render json: { "error": "invalid JSON"},
                           status: 400
                end
            end
        end
    end
end