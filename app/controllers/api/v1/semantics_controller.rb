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
                    if Semantic.first.validation.to_s == ""
                        render plain: "",
                               status: 404
                    else
                        render plain: Semantic.first.validation, 
                               status: 200
                    end
                end
            end

            def show_info
                if Semantic.count == 0
                    render json: {},
                           status: 200
                else
                    if Semantic.first.validation.to_s == ""
                        render json: {},
                               status: 200
                    else
                        init = RDF::Repository.new()
                        init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
                        uc = nil
                        init.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "BaseConfiguration" ? uc = g : nil }
                        title = RDF::Query.execute(uc) { pattern [:subject, RDF::URI.new(PURL_TITLE), :value] }.first.value.to_s
                        description = RDF::Query.execute(uc) { pattern [:subject, RDF::URI.new(PURL_DESCRIPTION), :value] }.first.value.to_s.strip
                        render json: { "name": title, 
                                       "description": description },
                               status: 200
                    end
                end
            end

            def show_usage
                if Semantic.count == 0
                    render json: {},
                           status: 200
                else
                    if Semantic.first.validation.to_s == ""
                        render json: {},
                               status: 200
                    else
                        render plain: container_usage_policy.to_s, 
                               status: 200
                    end
                end
            end

            def show_example
                if Semantic.count == 0
                    render json: {},
                           status: 200
                else
                    if Semantic.first.validation.to_s == ""
                        render json: {},
                               status: 200
                    else
                        init = RDF::Repository.new()
                        init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
                        uc = nil
                        init.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "BaseConfiguration" ? uc = g : nil }
                        example = RDF::Query.execute(uc) { pattern [:subject, RDF::URI.new(SEMCON_ONTOLOGY + "hasExampleData"), :value] }.first.value.to_s.strip
                        render plain: example.to_s,
                               status: 200
                    end
                end
            end             

            def create
                input_raw = params.to_json
                if Semantic.count == 0 or Semantic.first.validation.to_s == ""
                    input = JSON.parse(input_raw)["init"].to_s

                    # check if input is valid
                    # https://github.com/ruby-rdf/rdf-reasoner
                    init = RDF::Reader.for(:trig).new(input)
                    image_constraints = RDF::Repository.load("./config/image-constraints.trig", format: :trig)

                    init_validation = {
                        "base-config": init.dump(:trig).to_s,
                        "image-constraints": image_constraints.dump(:trig).to_s
                    }.stringify_keys

                    # get init_validataion_url
                    uf = nil
                    image_constraints.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "ImageConfiguration" ? uf = g : nil }
                    init_validation_url = RDF::Query.execute(uf) { pattern [:subject, RDF::URI.new(SEMCON_ONTOLOGY + "initValidationService"), :value] }.first.value.to_s
                    if init_validation_url == ""
                        init_validation_url = SEMANTIC_SERVICE + "/validate/init"
                    end

                    response = HTTParty.post(init_validation_url, 
                        headers: { 'Content-Type' => 'application/json' },
                        body: init_validation.to_json)

                    # check if input is valid
                    if response.code.to_s == "200"
                        if Semantic.count == 0
                            Semantic.new(validation: input).save
                        else
                            Semantic.first.update_attributes(validation: input)
                        end
                        createLog({
                            "type": "write",
                            "scope": "meta information"})
                        render plain: "",
                               status: 200
                    else
                        render json: { "error": "input is not valid"},
                               status: 422
                        return
                    end
                else
                    render json: { "error": "container already initialized"},
                           status: 409
                end
            end
        end
    end
end