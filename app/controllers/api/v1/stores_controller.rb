module Api
    module V1
        class StoresController < ApiController
            include ApplicationHelper
            include DataAccessHelper
            include DataWriteHelper
            include ProvenanceHelper

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def index # /api/data
                if ENV["AUTH"].to_s.downcase == "billing" && !valid_doorkeeper_token?
                    billing = {
                        "payment-info": payment_info_text.to_s,
                        "payment-methods": ["Ether"],
                        "provider": payment_seller_email.to_s,
                        "provider-pubkey-id": payment_seller_pubkey_id.to_s
                    }.stringify_keys

                    billing_hash = Digest::SHA256.hexdigest(billing.to_json)
                    param_str = request.query_string.to_s
                    timeStart = Time.now.utc
                    timeEnd = Time.now.utc

                    provision = {
                        "usage-policy": container_usage_policy.to_s,
                        "provenance": getProvenance(billing_hash, param_str, timeStart, timeEnd)
                    }.stringify_keys
                    provision_hash = Digest::SHA256.hexdigest(billing.to_json + ", " + provision.to_json)
                else
                    provision = get_provision(params, "read")
                    provision_hash = Digest::SHA256.hexdigest(provision.to_json)
                end
                begin
                    response = HTTParty.post("https://blockchain.ownyourdata.eu/api/doc?hash=" + provision_hash.to_s)
                rescue => ex
                    response = nil
                end

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

                if ENV["AUTH"].to_s.downcase == "billing" && !valid_doorkeeper_token?
                    retVal = {
                        "billing": billing,
                        "provision": provision,
                        "validation": {
                            "hash": provision_hash,
                            "dlt-reference": dlt_reference
                        }
                    }.stringify_keys
                else
                    retVal = {
                        "provision": provision,
                        "validation": {
                            "hash": provision_hash,
                            "dlt-reference": dlt_reference
                        }
                    }.stringify_keys
                end

                render json: retVal.to_json, 
                       status: 200
            end

            def plain # /api/data/plain
                if ENV["AUTH"].to_s.downcase == "billing" && !valid_doorkeeper_token?
                    billing = {
                        "payment-info": payment_info_text.to_s,
                        "methods": ["Ether"],
                        "provider": payment_seller_email.to_s,
                        "provider-pubkey-id": payment_seller_pubkey_id.to_s
                    }.stringify_keys
                    retVal = billing.to_json
                else
                    retVal_type = container_format
                    retVal_data = getData(params)
                    if retVal_data.nil?
                        retVal_data = []
                    end
                    case retVal_type.to_s
                    when "JSON"
                        retVal = []
                        retVal_data.each { |item| retVal << JSON(item) } rescue nil
                        retVal = retVal.to_json
                    else
                        retVal = retVal_data.join("\n")
                    end                    
                    createLog({
                        "type": "read plain " + retVal_type.to_s,
                        "scope": "all (" + retVal_data.count.to_s + " records)",
                        "request": request.remote_ip.to_s}.to_json)
                end
                render plain: retVal, 
                       status: 200
            end

            def full # /api/data/full
                if ENV["AUTH"].to_s.downcase == "billing" && !valid_doorkeeper_token?
                    billing = {
                        "payment-info": payment_info_text.to_s,
                        "methods": ["Ether"],
                        "provider": payment_seller_email.to_s,
                        "provider-pubkey-id": payment_seller_pubkey_id.to_s
                    }.stringify_keys

                    billing_hash = Digest::SHA256.hexdigest(billing.to_json)
                    param_str = request.query_string.to_s
                    timeStart = Time.now.utc
                    timeEnd = Time.now.utc

                    provision = {
                        "usage-policy": container_usage_policy.to_s,
                        "provenance": getProvenance(billing_hash, param_str, timeStart, timeEnd)
                    }.stringify_keys
                    provision_hash = Digest::SHA256.hexdigest(billing.to_json + ", " + provision.to_json)
                else
                    provision = get_provision(params, "read - full")
                    provision_hash = Digest::SHA256.hexdigest(provision.to_json)
                end
                begin
                    response = HTTParty.post("https://blockchain.ownyourdata.eu/api/doc?hash=" + provision_hash.to_s)
                rescue => ex
                    response = nil
                end

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
                    trusted_timestamp = response.parsed_response["tsr"]
                end

                if ENV["AUTH"].to_s.downcase == "billing" && !valid_doorkeeper_token?
                    retVal = {
                        "billing": billing,
                        "provision": provision,
                        "validation": {
                            "hash": provision_hash,
                            "trusted-timestamp": trusted_timestamp,
                            "dlt-reference": dlt_reference
                        }
                    }.stringify_keys
                else
                    retVal = {
                        "provision": provision,
                        "validation": {
                            "hash": provision_hash,
                            "trusted-timestamp": trusted_timestamp,
                            "dlt-reference": dlt_reference
                        }
                    }.stringify_keys
                end

                render json: retVal.to_json, 
                       status: 200                       
            end

            def provision # /api/data/provision
                if ENV["AUTH"].to_s.downcase == "billing" && !valid_doorkeeper_token?
                    billing = {
                        "payment-info": payment_info_text.to_s,
                        "methods": ["Ether"],
                        "provider": payment_seller_email.to_s,
                        "provider-pubkey-id": payment_seller_pubkey_id.to_s
                    }.stringify_keys

                    billing_hash = Digest::SHA256.hexdigest(billing.to_json)
                    param_str = request.query_string.to_s
                    timeStart = Time.now.utc
                    timeEnd = Time.now.utc

                    provision = {
                        "usage-policy": container_usage_policy.to_s,
                        "provenance": getProvenance(billing_hash, param_str, timeStart, timeEnd)
                    }.stringify_keys

                    retVal = {"billing": billing, "provision": provision}.stringify_keys
                else
                    retVal = get_provision(params, "read - provision only")
                end

                render json: retVal.to_json, 
                       status: 200
            end

            def write
                begin
                    if params.include?("_json")
                        input = JSON.parse(params.to_json)["_json"]
                        other = JSON.parse(params.to_json).except("_json", "store", "format", "controller", "action", "application")
                        if other != {}
                            input += [other]
                        end
                    else
                        input = JSON.parse(params.to_json).except("store", "format", "controller", "action", "application")
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
                        content = input["provision"]["content"] rescue ""
                        usage_policy = input["provision"]["usage-policy"] rescue ""
                        provenance = input["provision"]["provenance"] rescue ""
                    else
                        if !input["content"].nil?
                            # has top-level "content" attribute
                            content = input["content"] rescue ""
                            usage_policy = input["usage-policy"] rescue ""
                            provenance = input["provenance"] rescue ""
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

                    if Semantic.count == 1
                        uc = nil
                        init = RDF::Repository.new()
                        init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
                        init.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "UsagePolicy" ? uc = g : nil }
                        if !uc.nil?
                            data_controller = uc.dump(:trig).to_s

                            intro  = "@prefix sc: <" + SEMCON_ONTOLOGY + "> .\n"
                            intro += "@prefix owl: <http://www.w3.org/2002/07/owl#> .\n"
                            intro += "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n"
                            intro += "@prefix spl: <http://www.specialprivacy.eu/langs/usage-policy#> .\n"
                            intro += "@prefix svd: <http://www.specialprivacy.eu/vocabs/data#> .\n"
                            intro += "@prefix xml: <http://www.w3.org/XML/1998/namespace> .\n"
                            intro += "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n"
                            intro += "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n"
                            intro += "@prefix svdu: <http://www.specialprivacy.eu/vocabs/duration#> .\n"

                            dataSubject_intro = "sc:DataSubjectPolicy rdf:type owl:Class ;\n"
                            data_subject = data_subject.strip.split("\n")[1..-1].join("\n")

                            dataController_intro = "sc:DataControllerPolicy rdf:type owl:Class ;\n"
                            data_controller = data_controller.strip.split("\n")[2..-2].join("\n")

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
                end
                writeData(content, input, provenance)

            end
        end
    end
end