module Api
    module V1
        class StoresController < ApiController
            include ApplicationHelper

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def index
                retVal = []
                Store.pluck(:item).each { |item| retVal << JSON(item) }

                createLog({
                    "type": "read",
                    "scope": "all (" + Store.count.to_s + " records)",
                    "request": request.remote_ip.to_s}.to_json)

                render json: retVal.to_json, 
                       status: 200
            end

            def write
                begin
                    new_items = []
                    if params.include?("_json")
                        input = JSON.parse(params.to_json)["_json"]
                    else
                        input = JSON.parse(params.to_json).except("store", "format", "controller", "action")
                    end
                    input.each do |item|
                        my_store = Store.new(item: item.to_json)
                        my_store.save
                        new_items << my_store.id
                    end

                    createLog({
                        "type": "write",
                        "scope": new_items.to_s,
                        "request": request.remote_ip.to_s}.to_json)
                    render plain: "",
                           status: 200
                rescue => ex
                    # puts ex.to_s
                    render plain: "",
                           status: 500
                end

                # if Semantic.count == 0
                #     render json: { "error": "semantic definition not set yet"},
                #            status: 412
                #     return
                # end

                # puts "Headers (Email): " + request.headers["Email"]
                # puts "Params: " + JSON.parse(params.to_json)['_json'].to_s
                # input = {
                #     "@context": JSON.parse(params["@context"].to_json),
                #     "@graph": JSON.parse(params["@graph"].to_json) }.stringify_keys

                # combine with semantic validation JSON
                # combined_data = {
                #     "content": input,
                #     "constraints": JSON.parse(Semantic.first.validation)
                # }

                # check if content is valid
                # data_validation_url = "https://semantic.ownyourdata.eu/api/validate/content"
                # response = HTTParty.post(data_validation_url, 
                #     headers: { 'Content-Type' => 'application/json' },
                #     body: combined_data.to_json )
                # if response.code.to_s == "200"
                #     Store.new(item: input.to_s.gsub('=>', ':')).save
                #     render plain: "", 
                #            status: 200
                # else
                #     render json: { "error": "data does not pass semantic validation"},
                #            status: 422
                #     return
                # end
            end
        end
    end
end