module PolicyMatchHelper
	# usage_policy - from Data Subject
	# container policy is from Data Controller

    def policy_match?(usage_policy)

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
            if Semantic.count > 0
                uc = nil
                init = RDF::Repository.new()
                init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
                init.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "UsagePolicy" ? uc = g : nil }
                if !uc.nil?
                    data_controller = uc.dump(:trig).to_s

                    intro  = "@prefix sc: <" + SEMCON_ONTOLOGY + "> .\n"
                    intro += "@prefix owl: <http://www.w3.org/2002/07/owl#> .\n"
                    intro += "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n"
                    intro += "@prefix xml: <http://www.w3.org/XML/1998/namespace> .\n"
                    intro += "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n"
                    intro += "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n"
                    intro += "@prefix spl: <http://www.specialprivacy.eu/langs/usage-policy#> .\n"
                    intro += "@prefix svd: <http://www.specialprivacy.eu/vocabs/data#> .\n"
                    intro += "@prefix svdu: <http://www.specialprivacy.eu/vocabs/duration#> .\n"
                    intro += "@prefix svr: <http://www.specialprivacy.eu/vocabs/recipients#> .\n"
                    intro += "@prefix svpu: <http://www.specialprivacy.eu/vocabs/purposes#> .\n"
                    intro += "@prefix svpr: <http://www.specialprivacy.eu/vocabs/processing#> .\n"
                    intro += "@prefix svl: <http://www.specialprivacy.eu/vocabs/locations#> .\n"
                    intro += "@prefix scp: <http://w3id.org/semcon/ns/policy#> .\n"

                    dataSubject_intro = "sc:DataSubjectPolicy rdf:type owl:Class ;\n"
                    data_subject = data_subject.strip.split("\n")[2..-2].join("\n")

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
                    	return false
                    end
                end
            end
        end

        return true

    end

end