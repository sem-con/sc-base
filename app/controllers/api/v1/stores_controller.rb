module Api
    module V1
        class StoresController < ApiController
            include ApplicationHelper
            include DataAccessHelper
            include DataWriteHelper
            include PolicyMatchHelper
            include ProvenanceHelper
            include PaymentHelper
            include PlantumlHelper
            include Pagy::Backend

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            after_action { pagy_headers_merge(@pagy) if @pagy }

            def index # /api/data
                if ENV["AUTH"].to_s.downcase == "billing" && !valid_doorkeeper_token?
                    billing = {
                        "payment-info": payment_info(params),
                        "payment-methods": payment_methods,
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

                    retVal = {
                        "billing": billing,
                        "provision": provision,
                        "validation": {
                            "hash": provision_hash,
                            "dlt-reference": dlt_reference
                        }
                    }.stringify_keys
                else
                    if params[:id].to_s != "" && params[:p].to_s == ""
                        render json: { "error": "missing paramter specification (p=id|dri)"},
                               status: 422
                        return
                    end

                    @pagy, provision = getProvision(params, "read " + params.to_json)
                    provision_hash = Digest::SHA256.hexdigest(provision.to_json)

                    if params[:f].to_s == "plain"
                        if params[:p].to_s == ""
                            retVal = []
                            provision["data"].each{ |el| retVal << el["content"] }
                        else
                            if provision == []
                                retVal = {}
                            else
                                retVal = provision["content"]
                            end
                        end

                    elsif params[:f].to_s == "meta"
                        if params[:p].to_s == ""
                            retVal = []
                            provision["data"].each{ |el| retVal << el.except("content", "usage-policy", "provenance") }
                        else
                            if provision == []
                                retVal = {}
                            else
                                retVal = provision.except("content", "usage-policy", "provenance")
                            end
                        end

                    elsif params[:f].to_s == "validation"
                        if params[:p].to_s == ""
                            retVal = {"data": provision["data"]}.stringify_keys
                        else
                            retVal = provision
                        end

                        response_error = false
                        response = nil
                        begin
                            response = HTTParty.post("https://blockchain.ownyourdata.eu/api/doc?hash=" + provision_hash.to_s)
                        rescue => ex
                            response_error = true
                            puts "Error: " +  ex.inspect.to_s
                        end

                        dlt_reference = ""
                        if !response_error && response.code.to_s == "200"
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

                    elsif params[:f].to_s == "provis"
                        retVal = [plantuml(provision)]
                        # retVal = ["@startuml\nallowmixing\nskinparam shadowing false\nactor :Person dri-p1s...: as p1\nstate \"Activity: **create cattle**\" as a1 #palegreen\na1 : ts: 2021-01-01T01:00:00Z ref: dri-a10s...\nmap \" Entity: ** Cattle ** \" as e1 {\n  id => 10\n  dri => dri-e10s...\n}\nnode s1 #aliceblue [\nAgent: **SemCon** (Farmer)\nsemcon/sc-base:latest\nguid: id-sc1s...\n]\na1 <-up- e1 : wasGeneratedBy\na1 -> s1 : wasAssociatedWith\ns1 <-left- e1 : attributedTo\ns1 --> p1 : actedOnBehalfOf\n@enduml"]
                    else # format=full
                        if provision == [] || provision == ""
                            if params[:p].to_s == ""
                                retVal = provision
                            else 
                                if provision == []
                                    retVal = {}
                                else
                                    retVal = provision
                                end
                            end
                        else
                            if params[:p].to_s == ""
                                retVal = {"data": provision["data"]}.stringify_keys
                            else
                                retVal = provision
                            end
                            if provision["usage-policy"].to_s != ""
                                retVal["usage-policy"] = provision["usage-policy"]
                            end
                            retVal["provenance"] = provision["provenance"]
                        end
                    end
                end

                render json: retVal.to_json, 
                       status: 200
            end

            def show_deprecated  # remove after Feb 2021
                if ENV["AUTH"].to_s.downcase == "billing" && !valid_doorkeeper_token?
                    billing = {
                        "payment-info": payment_info,
                        "methods": ["Ether", "PayPal"],
                        "provider": payment_seller_email.to_s,
                        "provider-pubkey-id": payment_seller_pubkey_id.to_s
                    }.stringify_keys
                    retVal = billing.to_json
                else
                    retVal_type = container_format
                    if (params[:id].to_i.to_s == params[:id].to_s)
                        retVal_data = getData("id=" + params[:id].to_s)
                    elsif (params["dri"].to_s != "")
                        retVal_data = getData("dri=" + params["dri"].to_s)
                    elsif (params["schema_dri"].to_s != "")
                        retVal_data = getData("schema_dri=" + params["schema_dri"].to_s)
                    elsif !(Date.parse(params[:id].to_s) rescue nil).nil?
                        retVal_data = getData("day=" + params[:id].to_s)
                    else
                        retVal_data = getData(params[:id].to_s)
                    end
                    if retVal_data.nil?
                        retVal_data = []
                    end
                    content = []
                    case retVal_type.to_s
                    when "JSON"
                        if retVal_data.count > 0
                            if retVal_data.first["item"].is_a? String 
                                retVal_data.each { |el| content << JSON(el["item"]) } rescue nil
                            else
                                retVal_data.each { |el| content << el["item"] } rescue nil
                            end
                        end
                    when "RDF"
                        retVal_data.each { |el| content << el["item"].to_s }
                    else
                        content = ""
                        retVal_data.each { |el| content += el["item"].to_s + "\n" } rescue ""
                    end

                    if retVal_type == "JSON"
                        createLog({
                            "type": "read plain " + retVal_type.to_s,
                            "scope": retVal_data.map{|h| h["id"]}.flatten.sort.to_json}, # "all (" + retVal_data.count.to_s + " records)"},
                            Digest::SHA256.hexdigest(content.to_json))
                        render json: content,
                               status: 200
                    else
                        createLog({
                            "type": "read plain " + retVal_type.to_s,
                            "scope": retVal_data.map{|h| h["id"]}.flatten.sort.to_json}, # "all (" + retVal_data.count.to_s + " records)"},
                            Digest::SHA256.hexdigest(content.to_s))
                        render plain: content,
                               status: 200
                    end
                end
            end

            def plain # /api/data/plain
                if ENV["AUTH"].to_s.downcase == "billing" && !valid_doorkeeper_token?
                    billing = {
                        "payment-info": payment_info,
                        "methods": ["Ether"],
                        "provider": payment_seller_email.to_s,
                        "provider-pubkey-id": payment_seller_pubkey_id.to_s
                    }.stringify_keys
                    render json: billing,
                           status: 200
                else
                    retVal_type = container_format
                    retVal_data = getData(params)
                    if retVal_data.nil?
                        retVal_data = []
                    end
                    content = []
                    case retVal_type.to_s
                    when "JSON"
                        if retVal_data.count > 0
                            if retVal_data.first["item"].is_a? String 
                                retVal_data.each { |el| content << JSON(el["item"]) }
                            else
                                retVal_data.each { |el| content << el["item"] }
                            end
                        end
                    when "RDF"
                        retVal_data.each { |el| content << el["item"].to_s }
                    else
                        content = ""
                        retVal_data.each { |el| content += el["item"].to_s + "\n" }
                    end

                    if retVal_type == "JSON"
                        createLog({
                            "type": "read plain " + retVal_type.to_s,
                            "scope": retVal_data.map{|h| h["id"]}.flatten.sort.to_json}, # "all (" + retVal_data.count.to_s + " records)"},
                            Digest::SHA256.hexdigest(content.to_json))
                        render json: content,
                               status: 200
                    else
                        createLog({
                            "type": "read plain " + retVal_type.to_s,
                            "scope": retVal_data.map{|h| h["id"]}.flatten.sort.to_json}, # "all (" + retVal_data.count.to_s + " records)"},
                            Digest::SHA256.hexdigest(content.to_s))
                        render plain: content,
                               status: 200
                    end
                end
            end

            def full # /api/data/full
                if ENV["AUTH"].to_s.downcase == "billing" && !valid_doorkeeper_token?
                    billing = {
                        "payment-info": payment_info,
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
                        "payment-info": payment_info,
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
                read_hash = ""
                usage_policy = ""
                content = []
                if JSON.parse(input.to_json).class == Hash
                    if !input["provision"].nil?
                        # has top-level "provision" attributes
                        content = input["provision"]["content"] rescue ""
                        usage_policy = input["provision"]["usage-policy"] rescue ""
                        provenance = input["provision"]["provenance"] rescue ""
                        read_hash = input["validation"]["hash"] rescue ""
                    else
                        if !input["content"].nil?
                            # has top-level "content" attribute
                            content = input["content"] rescue ""
                            usage_policy = input["usage-policy"] rescue ""
                            provenance = input["provenance"] rescue ""
                            read_hash = input["validation"]["hash"] rescue ""
                        else
                            # simple array with data
                            content = input
                            read_hash = Digest::SHA256.hexdigest(input.to_json)
                        end
                    end
                else
                    content = input
                    read_hash = Digest::SHA256.hexdigest(input.to_json)
                end
                if read_hash == ""
                    read_hash = Digest::SHA256.hexdigest(content.to_json)
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
                if !policy_match?(usage_policy)
                    createLog({
                        "type": "write",
                        "scope": "invalid usage-policy"})

                    render json: { "error": "provided usage policy not applicable for container" },
                           status: 412
                    return
                end

                writeData(content, input, provenance, read_hash)

            end

            def delete
                if params["p"].to_s == "id"
                    @item = Store.find(params["id"]) rescue nil
                elsif params["p"].to_s == "dri"
                    @item = Store.find_by_dri(params["id"]) rescue nil
                else
                    render json: { "error": "invalid paramenter" },
                           status: 422
                    return
                end

                if @item.nil?
                    render json: { "error": "not found" },
                           status: 404
                    return
                end                    
                retVal = { "id": @item.id }.stringify_keys
                if @item.dri.to_s != ""
                    retVal["dri"] = @item.dri.to_s
                end
                @item.delete
                createLog({
                    "type": "delete",
                    "scope": "id: " + retVal["id"].to_s})

                render json: retVal,
                       status: 200
            end
        end
    end
end