module Api
    module V1
        class StoresController < ApiController
            include ApplicationHelper
            include DataAccessHelper
            include ProvenanceHelper

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def get_provision(params, logstr)
                retVal_type = container_format
                retVal_data = getData(params)
                content = []
                case retVal_type.to_s
                when "JSON"
                    retVal_data.each { |item| content << JSON(item) }
                when "RDF"
                    retVal_data.each { |item| content << item.to_s }
                else
                    content = retVal_data.join("\n")
                end

                createLog({
                    "type": logstr,
                    "scope": "all (" + retVal_data.count.to_s + " records)",
                    "request": request.remote_ip.to_s}.to_json)

                {
                    "content": content,
                    "usage-policy": container_usage_policy.to_s,
                    "provenance": getProvenance
                }.stringify_keys
            end

            def index # /api/data
                provision = get_provision(params, "read")
                provision_hash = Digest::SHA256.hexdigest(provision.to_json)
                begin
                    response = HTTParty.post("https://blockchain.ownyourdata.eu/api/doc?hash=" + provision_hash.to_s)
                rescue => ex
                    response = nil
                end

                # puts "URL: " + "https://blockchain.ownyourdata.eu/api/doc?hash=" + provision_hash.to_s
                # puts "response: " + response.code.to_s
                dlt_reference = ""
                if !response.nil? && response.code.to_s == "200"
                    if response.parsed_response["address"] == ""
                        dlt_reference = "https://notary.ownyourdata.eu/en?hash=" + provision_hash.to_s
                    else
                        dlt_reference = {
                            "dlt": "Ethereum",
                            "address": response.parsed_response["address"],
                            "audit-proof": response.parsed_response["audit-proof"]
                        }.stringify_keys
                    end
                end

                retVal = {
                    "provision": provision,
                    "validation": {
                        "hash": provision_hash,
                        "dlt-reference": dlt_reference
                    }
                }.stringify_keys

                render json: retVal.to_json, 
                       status: 200
            end

            def plain # /api/data/plain
                retVal_type = container_format
                retVal_data = getData(params)
                case retVal_type.to_s
                when "JSON"
                    retVal = []
                    retVal_data.each { |item| retVal << JSON(item) }
                    render json: retVal, 
                           status: 200
                else
                    retVal = retVal_data.join("\n")
                    render plain: retVal, 
                           status: 200
                end                    
                createLog({
                    "type": "read plain " + retVal_type.to_s,
                    "scope": "all (" + retVal_data.count.to_s + " records)",
                    "request": request.remote_ip.to_s}.to_json)

            end

            def full # /api/data/full
                provision = get_provision(params, "read - full")
                provision_hash = Digest::SHA256.hexdigest(provision.to_json)
                begin
                    response = HTTParty.post("https://blockchain.ownyourdata.eu/api/doc?hash=" + provision_hash.to_s)
                rescue => ex
                    response = nil
                end

                # puts "URL: " + "https://blockchain.ownyourdata.eu/api/doc?hash=" + provision_hash.to_s
                # puts "response: " + response.code.to_s
                dlt_reference = ""
                trusted_timestamp = ""
                if !response.nil? && response.code.to_s == "200"
                    if response.parsed_response["address"] == ""
                        dlt_reference = "https://notary.ownyourdata.eu/en?hash=" + provision_hash.to_s
                    else
                        dlt_reference = {
                            "dlt": "Ethereum",
                            "address": response.parsed_response["address"],
                            "audit-proof": response.parsed_response["audit-proof"]
                        }.stringify_keys
                    end
                    trusted_timestamp = response.parsed_response["tsr"]
                end

                retVal = {
                    "provision": provision,
                    "validation": {
                        "hash": provision_hash,
                        "trusted-timestamp": trusted_timestamp,
                        "dlt-reference": dlt_reference
                    }
                }.stringify_keys

                render json: retVal.to_json, 
                       status: 200
            end

            def provision # /api/data/provision
                retVal = get_provision(params, "read - provision only")

                render json: retVal.to_json, 
                       status: 200

            end

            def write
                begin
                    if params.include?("_json")
                        input = JSON.parse(params.to_json)["_json"]
                    else
                        input = JSON.parse(params.to_json).except("store", "format", "controller", "action")
                    end
                rescue => ex
                    render plain: "",
                           status: 422
                    return
                end
                # get input

                # determine type of input
                # 1) simple array with data
                # 2) has top-level "content" attribute
                # 3) has top-level "provision" attributes
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
                        end
                    end
                else
                    content = input
                end

                cf = container_format
                case cf
                when "CSV"
                    col_sep = ","
                    begin
                        suppress_output do
                            tmp = CSV.parse(content, headers: true, col_sep: ",")
                        end
                    rescue => ex
                        begin
                            suppress_output do
                                tmp = CSV.parse(content, headers: true, col_sep: ";")
                            end
                        rescue => ex
                            render plain: "",
                                   status: 422
                            return
                        end
                        col_sep = ";"
                    end
                    if Store.count > 0
                        # omit header if there is already data
                        content = content.split("\n").drop(1)
                    else
                        content = content.split("\n")
                    end

                when "JSON"
                    # nothing to do, content is already JSON

                when "RDF"
                    submission = RDF::Repository.new()
                    begin
                        suppress_output do
                            submission << RDF::Reader.for(:ttl).new(content.to_s)
                        end
                    rescue => ex
                        render plain: "",
                               status: 422
                        return
                    end
                    if submission.count > 0
                        content = submission.dump(:ttl).strip.split(" .").map { |e| "#{e.strip} ." }
                        # validate data format ======================
                        
                        # get data validation URL
                        bc = nil
                        image_constraints = RDF::Repository.load("./config/image-constraints.trig", format: :trig)
                        image_constraints.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "ImageConfiguration" ? bc = g : nil }
                        data_validation_url = RDF::Query.execute(bc) { pattern [:subject, RDF::URI.new(SEMCON_ONTOLOGY + "dataValidationService"), :value] }.first.value.to_s rescue ""
                        if data_validation_url == ""
                            data_validation_url = SEMANTIC_SERVICE + "/validate/data"
                        end

                        # build data validation JSON
                        dc = data_constraints.to_s
                        if dc != ""
                            record = {
                                "content-data": content.join("\n"),
                                "content-constraints": dc
                            }.stringify_keys
                            
                            # query service if data is valid
                            response = HTTParty.post(data_validation_url, 
                                headers: { 'Content-Type' => 'application/json' },
                                body: record.to_json)

                            if response.code.to_s != "200"
                                render json: { "error": "data does not match semantic constraints" },
                                       status: 412
                                return
                            end
                        end
                    else
                        content = ""
                    end
                end

                # validate if provided usage policy (Data Subject) 
                # conforms to container policy (Data Controller) ==========

                if usage_policy.to_s != ""
                    # get validation URL
                    bc = nil
                    image_constraints = RDF::Repository.load("./config/image-constraints.trig", format: :trig)
                    image_constraints.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "ImageConfiguration" ? bc = g : nil }
                    usage_matching_url = RDF::Query.execute(bc) { pattern [:subject, RDF::URI.new(SEMCON_ONTOLOGY + "usagePolicyValidationService"), :value] }.first.value.to_s
                    if usage_matching_url == ""
                        usage_matching_url = SEMANTIC_SERVICE + "/validate/usage-policy"
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

                    uc = nil
                    init = RDF::Repository.new()
                    init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
                    init.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "UsagePolicy" ? uc = g : nil }
                    if !uc.nil?
                        data_controller = uc.dump(:trig).to_s

                        intro  = "@prefix sc: <" + SEMCON_ONTOLOGY + "> .\n"
                        intro += "@prefix owl: <http://www.w3.org/2002/07/owl#> .\n"
                        intro += "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n"
                        intro += "@prefix spl: <https://www.specialprivacy.eu/langs/usage-policy#> .\n"
                        intro += "@prefix svd: <http://www.specialprivacy.eu/vocabs/data#> .\n"
                        intro += "@prefix xml: <http://www.w3.org/XML/1998/namespace> .\n"
                        intro += "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n"
                        intro += "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n"

                        dataSubject_intro = "sc:DataSubjectPolicy rdf:type owl:Class ;\n"
                        data_subject = data_subject.strip.split("\n")[2..-1].join("\n")

                        dataController_intro = "sc:DataControllerPolicy rdf:type owl:Class ;\n"
                        data_controller = data_controller.strip.split("\n")[3..-2].join("\n")

                        usage_matching = {
                            "usage-policy": intro + dataSubject_intro + data_subject + "\n" + dataController_intro + data_controller
                        }.stringify_keys

                        # query service if policies match
                        response = HTTParty.post(usage_matching_url, 
                            headers: { 'Content-Type' => 'application/json' },
                            body: usage_matching.to_json)

                        if response.code.to_s != "200"
                            createLog({
                                "type": "write",
                                "scope": "invalid usage-policy",
                                "request": request.remote_ip.to_s}.to_json)

                            render json: { "error": "provided usages policy not applicable for container" },
                                   status: 412
                            return
                        end
                    end
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
                        case cf
                        when "RDF", "CSV"
                            my_store = Store.new(item: item)
                        else
                            my_store = Store.new(item: item.to_json)
                        end
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