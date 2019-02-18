module ProvenanceHelper
    def getProvenance()
		prov = "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n"
		prov += "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n"
		prov += "@prefix owl: <http://www.w3.org/2002/07/owl#> .\n"
		prov += "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n"
		prov += "@prefix foaf: <http://xmlns.com/foaf/0.1/> .\n"
		prov += "@prefix void: <http://rdfs.org/ns/void#> .\n"
		prov += "@prefix prov: <http://www.w3.org/ns/prov#> .\n"
		prov += "@prefix sc: <http://w3id.org/semcon/ns/ontology#> .\n"
		prov += "@prefix scr: <http://w3id.org/semcon/resource/> .\n\n"

		prov += "scr:zamg a foaf:Organization, prov:Organization ;\n"
		prov += '	foaf:name "Zentralanstalt für Meteorologie und Geodynamik" ;' + "\n"
		prov += "	foaf:mbox <mailto:dion@zamg.ac.at> ;\n"
		prov += ".\n\n"
		prov += "scr:seismicContainer a prov:SoftwareAgent ;\n"
		prov += '	rdfs:label "seismic activities provided as Open Data"^^xsd:string ;' + "\n"
		if Semantic.count > 0
			prov += '	sc:containerInstanceID "' + Semantic.first.uid.to_s + '"^^xsd:string ;' + "\n"
		end
		if ENV["IMAGE_SHA256"].to_s != ""
			prov += '	sc:imageHash "' + ENV["IMAGE_SHA256"].to_s + '"^^xsd:string ;' + "\n"
		end
		prov += "	prov:actedOnBehalfOf scr:zamg ;\n"
		prov += ".\n"

		prov
    end
end
