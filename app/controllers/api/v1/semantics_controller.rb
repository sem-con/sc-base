module Api
    module V1
        class SemanticsController < ApiController
            include ApplicationHelper
            
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
                    render plain: "",
                           status: 404
                else
                    render plain: Semantic.first.validation, 
                           status: 200
                end
            end

            def show_info
                if Semantic.count == 0
                    render json: {},
                           status: 200
                else
                    init = RDF::Repository.new()
                    init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
                    uc = nil
                    init.each_graph{ |g| g.graph_name == "http://semantics.id/ns/semcon#UserConfigurations" ? uc = g : nil }
                    title = RDF::Query.execute(uc) { pattern [:subject, RDF::URI.new("http://purl.org/dc/elements/1.1/title"), :value] }.first.value.to_s
                    description = RDF::Query.execute(uc) { pattern [:subject, RDF::URI.new("http://purl.org/dc/elements/1.1/description"), :value] }.first.value.to_s.strip
                    render json: { "name": title, 
                                   "description": description },
                           status: 200
                end
            end

            def show_example
                if Semantic.count == 0
                    render json: {},
                           status: 200
                else
                    init = RDF::Repository.new()
                    init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
                    uc = nil
                    init.each_graph{ |g| g.graph_name == "http://semantics.id/ns/semcon#UserConfigurations" ? uc = g : nil }
                    example = RDF::Query.execute(uc) { pattern [:subject, RDF::URI.new("http://semantics.id/ns/semcon#exampleData"), :value] }.first.value.to_s.strip
                    render json: { "example": example },
                           status: 200
                end
            end             

            def create
                input_raw = params.to_json
                if Semantic.count == 0
                    input = JSON.parse(input_raw)["init"].to_s

                    # check if input is valid
                    # https://github.com/ruby-rdf/rdf-reasoner
                    base_constraints = RDF::Repository.load("./config/base-constraints.ttl", format: :trig)
                    init = RDF::Reader.for(:trig).new(input)

                    # # check if input is valid
                    # shacl_validation_url = "https://semantic.ownyourdata.eu/api/validate/shacl"
                    # response = HTTParty.post(shacl_validation_url, body: input )
                    # if response.code.to_s == "200"
                        Semantic.new(validation: input).save
                        createLog({
                            "type": "write",
                            "scope": "meta information",
                            "request": request.remote_ip.to_s}.to_json)
                        render plain: "",
                               status: 200
                    # else
                    #     render json: { "error": "input is not a valid Shacl constraint"},
                    #            status: 422
                    #     return
                    # end
                else
                    render json: { "error": "validation already set"},
                           status: 409
                end
            end
        end
    end
end