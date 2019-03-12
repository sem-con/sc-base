module ProvenanceActivityHelper
	def getProvenanceActivity(data_hash, container_uid, param_str, timeStart, timeEnd)

		prov = ""
		# Activity
		# iterate over all items in provenance table
		Provenance.all.each do |p|
			prov += "scr:input_" + p.input_hash[0,12] + " a prov:Activity;\n"
			prov += '    sc:inputHash "' + p.input_hash + '"^^xsd:string;' + "\n"
			prov += '    rdfs:label "input data from ' + p.endTime.iso8601 + '"^^xsd:string;' + "\n"
			if p.prov.to_s != ""
			 	prov += "    prov:used " + p.prov[/scr:data_.{21}/] + ";\n" rescue ""
			end
			prov += '    prov:startedAtTime "' + p.startTime.iso8601 + '"^^xsd:dateTime;' + "\n"
			prov += '    prov:endedAtTime "' + p.endTime.iso8601 + '"^^xsd:dateTime;' + "\n"
			prov += "    prov:generated scr:data_" + data_hash[0,12] + "_" + container_uid[0,8] + ";\n"
			prov += ".\n\n"

			if p.prov.to_s != ""
			 	prov += p.prov.gsub(/(^@prefix.+)/, '').strip rescue ""
			 	prov += "\n\n"
			end

		end

		prov.strip

	end
end
