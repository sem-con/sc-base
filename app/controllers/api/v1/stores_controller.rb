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

                render json: retVal, 
                       status: 200
            end

            def write
                # get input
                if params.include?("_json")
                    input = JSON.parse(params.to_json)["_json"]
                else
                    input = JSON.parse(params.to_json).except("store", "format", "controller", "action")
                end

                # determine type of input
                # 1) simple array with data
                # 2) has top-level "content" attribute
                # 3) has top-level "provision" attributes
                is_trig = true
                usage_policy = ""
                content = []
                if input.class == Hash
                    if !input["provision"].nil?
                        # has top-level "provision" attributes
                        content = input["provision"]["content"]
                        usage_policy = input["provision"]["usage-policy"]
                    else
                        if !input["content"].nil?
                            # has top-level "content" attribute
                            content = input["content"]
                            usage_policy = input["usage-policy"]
                        else
                            # simple array with data
                            content = input
                            is_trig = false
                        end
                    end
                else
                    is_trig = false
                    content = input
                end

                if is_trig
                    # check if it is a valid trig
                    submission = RDF::Repository.new()
                    begin
                        suppress_output do
                            submission << RDF::Reader.for(:ttl).new(content.to_s)
                        end
                    rescue => ex
                        is_trig = false
                    end
                end
                if is_trig
                    is_trig = (submission.count > 0)
                end

                # if it is a valid trig ...
                if is_trig
                    # ... extract data
                    content = submission.dump(:ttl).strip.split(" .").map { |e| "#{e.strip} ." }

                    # validate if provided usage policy (Data Subject) 
                    # conforms to container policy (Data Controller) ==========

                    # get validation URL
                    bc = nil
                    base_constraints = RDF::Repository.load("./config/base-constraints.trig", format: :trig)
                    base_constraints.each_graph{ |g| g.graph_name == "http://semantics.id/ns/semcon#BaseConfiguration" ? bc = g : nil }
                    usage_matching_url = RDF::Query.execute(bc) { pattern [:subject, RDF::URI.new("http://semantics.id/ns/semcon#usagePolicyValidationService"), :value] }.first.value.to_s
                    if usage_matching_url == ""
                        usage_matching_url = "https://semantic.ownyourdata.eu/api/validate/usage-policy"
                    end

                    # build usage matching trig
                    up = RDF::Repository.new()
                    begin
                        suppress_output do
                            up << RDF::Reader.for(:trig).new(usage_policy.to_s)
                        end
                    rescue => ex
                        
                    end

                    data_subject = up.dump(:trig).to_s

                    init = RDF::Repository.new()
                    init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
                    uc = nil
                    init.each_graph{ |g| g.graph_name == "http://semantics.id/ns/semcon#UsagePolicy" ? uc = g : nil }
                    data_controller = uc.dump(:trig).to_s

                    intro  = "@prefix sc: <http://semantics.id/ns/semcon#> .\n"
                    intro += "@prefix owl: <http://www.w3.org/2002/07/owl#> .\n"
                    intro += "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n"
                    intro += "@prefix spl: <https://www.specialprivacy.eu/langs/usage-policy#> .\n"
                    intro += "@prefix svd: <http://www.specialprivacy.eu/vocabs/data#> .\n"
                    intro += "@prefix xml: <http://www.w3.org/XML/1998/namespace> .\n"
                    intro += "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n"
                    intro += "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n"

                    dataSubject_intro = "sc:DataSubjectPolicy rdf:type owl:Class ;\n"
                    data_subject = data_subject.split("\n")[2..-1].join("\n")

                    dataController_intro = "sc:DataControllerPolicy rdf:type owl:Class ;\n"
                    data_controller = data_controller.split("\n")[3..-2].join("\n")

                    usage_matching = {
                        "usage-policy": intro + dataSubject_intro + data_subject + "\n" + dataController_intro + data_controller
                    }.stringify_keys

                    # query service if policies match
                    response = HTTParty.post(usage_matching_url, 
                        headers: { 'Content-Type' => 'application/json' },
                        body: usage_matching.to_json)

                    if response.code.to_s != "200"
                        render json: { "error": "provided usages policy not applicable for container" },
                               status: 500
                        return
                    end

                    # validate data format ======================

                else
                    content = input
                end

                # write data to container store
                new_items = []
                begin
                    if content.class == String
                        if content == ""
                            render plain: "",
                                   status: 500
                            return
                        end
                        content = [content]
                    end
                    content.each do |item|
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
                    render plain: "",
                           status: 500
                end
            end
        end
    end
end