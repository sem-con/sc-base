module ProvenanceActivityHelper
	def getProvenanceActivity(data_hash, container_uid, param_str, timeStart, timeEnd, ids)

		prov = ""
		# Activity
		# iterate over all items in provenance table

		@provenance = Provenance.all
		if ids.count > 0
			ids.each do |id|
				if ActiveRecord::Base.connection.class.to_s.include?("SQLite3")
					@provenance = Provenance.where("scope REGEXP '\\D#{id}\\D'")
				else
					@provenance = Provenance.where("scope ~ '\\D#{id}\\D'")
				end
				@provenance.each do |p|
					prov += build_prov(p, data_hash, container_uid)
				end unless @provenance.count == 0
			end
		else
			@provenance = Provenance.all
			@provenance.each do |p|
				prov += build_prov(p, data_hash, container_uid)
			end unless @provenance.count == 0
		end			
		prov.strip

	end

	def build_prov(p, data_hash, container_uid)
		prov = "scr:input_" + p.input_hash[0,12] + " a prov:Activity;\n"
		prov += '    sc:inputHash "' + p.input_hash + '"^^xsd:string;' + "\n"
		if !p.endTime.nil?
			prov += '    rdfs:label "input data from ' + p.endTime.iso8601 + '"^^xsd:string;' + "\n"
		end
		if p.prov.to_s != ""
		 	prov += "    prov:used " + p.prov[/scr:data_\w*/] + ";\n" rescue ""
		end
		if !p.startTime.nil?
			prov += '    prov:startedAtTime "' + p.startTime.iso8601 + '"^^xsd:dateTime;' + "\n"
		end
		if !p.endTime.nil?
			prov += '    prov:endedAtTime "' + p.endTime.iso8601 + '"^^xsd:dateTime;' + "\n"
		end
		prov += "    prov:generated scr:data_" + data_hash[0,12] + "_" + container_uid[0,8] + ";\n"
		prov += ".\n\n"

		if p.prov.to_s != ""
		 	prov += p.prov.gsub(/(^@prefix.+)/, '').strip rescue ""
		 	prov += "\n\n"
		end
		prov
	end
end
