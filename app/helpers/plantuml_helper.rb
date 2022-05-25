module PlantumlHelper
    def plantuml(provision)
        begin
            retVal = "@startuml\nallowmixing\nskinparam shadowing false\n"

            prov = provision["provenance"]
            name = nil
            begin
                init = RDF::Repository.new()
                init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
                uc = nil
                init.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "BaseConfiguration" ? uc = g : nil }
                name  = RDF::Query.execute(uc) { pattern [:subject, RDF::URI.new("http://xmlns.com/foaf/0.1/name"), :value] }.first.value.to_s
            rescue
                name = ""
            end

            retVal += 'state "Activity: **create Record**" as a1 #palegreen' + "\n"
            retVal += "a1 : "
            retVal += "ts: " + prov[/input data from (.*)\"\^\^/, 1] + "\\n"
            retVal += "ref: " + prov[/inputHash \"(.*)\"\^\^/, 1] + "\n"

            retVal += 'map " Entity: ** Record ** " as e1 {' + "\n"
            retVal += "  id => " + provision["id"].to_s + "\n"
            if provision["dri"].to_s != ""
                retVal += "  dri => " + provision["dri"].to_s + "\n"
            end
            retVal += "}\n"

            retVal += "node s1 #aliceblue [\n"
            retVal += "Agent: **Semantic Container**\n"
            retVal += "image: " + ENV["IMAGE_NAME"].to_s + "\n"
            retVal += "guid: " + Semantic.first.uid.to_s + "\n"
            retVal += "]\n"

            retVal += "a1 <-up- e1 : wasGeneratedBy\n"
            retVal += "a1 -> s1 : wasAssociatedWith\n"
            retVal += "s1 <-left- e1 : attributedTo\n"

            if name.to_s != ""
                retVal += 'actor :Person "' + name.to_s + '": as p1' + "\n"
                retVal += "s1 --> p1 : actedOnBehalfOf\n"
            end

            retVal += "@enduml"
        rescue
            retVal = "@startuml\nobject Response\nResponse : Provenance cannot be displayed\n@enduml"
        end

        return retVal
    end
end