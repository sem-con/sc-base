module ApplicationHelper
    def createLog(value, read_hash="")
        app_id = doorkeeper_token.application_id rescue nil;
        if !app_id.nil?
            value["app_id"] = app_id
        end
        value["request"] = request.remote_ip.to_s
        Log.new(item: value.to_json, read_hash: read_hash).save
    end

    def createReceipt(input_hash, item_ids, timestamp)
        {
            "input_hash": input_hash,
            "item_ids": item_ids,
            "timestamp": timestamp.iso8601,
            "sc_uid": Semantic.first.uid
        }
    end

    def container_format
        if Semantic.count > 0 and Semantic.first.validation.to_s != ""
            # check data format in configuration
            init = RDF::Repository.new()
            init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
            ic = nil
            init.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "BaseConfiguration" ? ic = g : nil }
            data_format = RDF::Query.execute(ic) { pattern [:subject, RDF::URI.new(SEMCON_ONTOLOGY + "hasNativeSyntax"), :value] }.first.value.to_s rescue ""
            case data_format.to_s
            when "http://www.w3.org/ns/formats/Turtle"
                "RDF"
            when SEMCON_ONTOLOGY + "JSON" #"http://www.w3id.org/semcon/formats/JSON"
                "JSON"
            when SEMCON_ONTOLOGY + "CSV"
                "CSV"
            else
                nil
            end
        else
            nil
        end
    end

    def container_usage_policy
        if Semantic.count > 0
            init = RDF::Repository.new()
            init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
            uc = nil
            init.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "UsagePolicy" ? uc = g : nil }
            if uc.nil?
                nil
            else
                uc.dump(:trig).to_s
            end
        else 
            nil
        end
    end

    def data_constraints
        if Semantic.count > 0
            init = RDF::Repository.new()
            init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
            dc = nil
            init.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "DataConstraint" ? dc = g : nil }
            if dc.nil?
                nil
            else
                dc.dump(:trig).to_s.strip.split("\n")[1..-2].join("\n")
            end
        else 
            nil
        end
    end

    def suppress_output
      begin
        original_stderr = $stderr.clone
        original_stdout = $stdout.clone
        $stderr.reopen(File.new('/dev/null', 'w'))
        $stdout.reopen(File.new('/dev/null', 'w'))
        retval = yield
      rescue Exception => e
        $stdout.reopen(original_stdout)
        $stderr.reopen(original_stderr)
        raise e
      ensure
        $stdout.reopen(original_stdout)
        $stderr.reopen(original_stderr)
      end
      retval
    end    
end
