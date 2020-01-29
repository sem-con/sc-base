module ProvenanceHelper
    include ProvenanceActivityHelper

    def getProvenance(data_hash, param_str, timeStart, timeEnd)

    	if Semantic.count == 0
    		return ""
    		exit
    	end
        image_hash = ENV["IMAGE_SHA256"].to_s
        container_uid = Semantic.first.uid.to_s
        init = RDF::Repository.new()
        init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
        uc = nil
        init.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "BaseConfiguration" ? uc = g : nil }
        container_title = RDF::Query.execute(uc) { pattern [:subject, RDF::URI.new(PURL_TITLE), :value] }.first.value.to_s rescue ""
        container_description = RDF::Query.execute(uc) { pattern [:subject, RDF::URI.new(PURL_DESCRIPTION), :value] }.first.value.to_s.strip rescue ""

        query = RDF::Query.new({
            person: {
                RDF.type => RDF::Vocab::FOAF.Person,
                RDF::Vocab::FOAF.name => :name,
                RDF::Vocab::FOAF.mbox => :email,
            }
        })
        operator_type = ""
        operator_name = query.execute(uc).first.name.to_s rescue ""
        operator_email = query.execute(uc).first.email.to_s.sub("mailto:","") rescue ""
        operator_hash = ""

        if operator_name == ""
            query = RDF::Query.new({
                person: {
                    RDF.type => RDF::Vocab::FOAF.Organization,
                    RDF::Vocab::FOAF.name => :name,
                    RDF::Vocab::FOAF.mbox => :email,
                }
            })
            operator_name = query.execute(uc).first.name.to_s rescue ""
            operator_email = query.execute(uc).first.email.to_s.sub("mailto:","") rescue ""
            if operator_name != ""
                operator_type = "org"
            end
        else
            operator_type = "person"
        end
        if operator_name != "" && operator_email != ""
           operator_hash = Digest::SHA256.hexdigest(
                operator_name + " <" + operator_email + ">") # hash('name <email>')
        end

        # header
        prov = "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n"
        prov += "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n"
        prov += "@prefix owl: <http://www.w3.org/2002/07/owl#> .\n"
        prov += "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n"
        prov += "@prefix foaf: <http://xmlns.com/foaf/0.1/> .\n"
        prov += "@prefix void: <http://rdfs.org/ns/void#> .\n"
        prov += "@prefix prov: <http://www.w3.org/ns/prov#> .\n"
        prov += "@prefix sc: <http://w3id.org/semcon/ns/ontology#> .\n"
        prov += "@prefix scr: <http://w3id.org/semcon/resource/> .\n\n"

        # Entity
        prov += "scr:data_" + data_hash[0,12] + "_" + container_uid[0,8] + " a prov:Entity;\n"
        prov += '    sc:dataHash "' + data_hash + '"^^xsd:string;' + "\n"
        prov += '    rdfs:label "data set from ' + Time.now.utc.iso8601 + '"^^xsd:string;' + "\n"
        if container_uid != ""
            prov += "    prov:wasAttributedTo scr:container_" + container_uid[0,13] + ";\n"
        end
        prov += '    prov:generatedAtTime "' + Time.now.utc.iso8601 + '"^^xsd:dateTime;' + "\n"
        prov += ".\n\n"

        # Agent
        if container_uid != ""
            prov += "scr:container_" + container_uid[0,13] + " a prov:softwareAgent;\n"
            prov += '    sc:containerInstanceId "' + container_uid + '"^^xsd:string;' + "\n"
            if image_hash != ""
                prov += '    sc:imageHash "' + image_hash + '"^^xsd:string;' + "\n"
            end
            if container_title != !""
                prov += '    rdfs:label "' + container_title + '"^^xsd:string;' + "\n"
            end
            if container_description != ""
                prov += '    rdfs:comment "' + container_description + '"^^xsd:string;' + "\n"
            end
            if operator_hash != ""
                prov += "    prov:actedOnBehalfOf scr:operator_" + operator_hash[0,12] + ";\n"
            end
            prov += ".\n\n"
        end

        # Agent - Operator information
        if operator_hash != ""
            case operator_type
            when "person"
                prov += "scr:operator_" + operator_hash[0,12] + " a foaf:Person, prov:Person;\n"
            when "org"
                prov += "scr:operator_" + operator_hash[0,12] + " a foaf:Organization, prov:Organization;\n"
            end
            prov += '    sc:operatorHash "' + operator_hash + '"^^xsd:string;' + "\n"
            prov += '    foaf:name "' + operator_name + '";' + "\n"
            prov += "    foaf:mbox <mailto:" + operator_email + ">;\n"
            prov += ".\n\n"
        end

        # Activity
        prov += getProvenanceActivity(data_hash, container_uid, param_str, timeStart, timeEnd)

        prov
    end
end
