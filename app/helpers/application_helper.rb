module ApplicationHelper
    def createLog(value)
        Log.new(item: value).save
    end

    def container_format
        if Semantic.count > 0 and Semantic.first.validation.to_s != ""
            # check data format in configuration
            init = RDF::Repository.new()
            init << RDF::Reader.for(:trig).new(Semantic.first.validation.to_s)
            ic = nil
            init.each_graph{ |g| g.graph_name == SEMCON_ONTOLOGY + "InitialConfiguration" ? ic = g : nil }
            data_format = RDF::Query.execute(ic) { pattern [:subject, RDF::URI.new(SEMCON_ONTOLOGY + "hasNativeSyntax"), :value] }.first.value.to_s # rescue ""
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
            uc.dump(:trig).to_s
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
