module ResolveHelper
    def resolve_did(did, options)
        if did.to_s == ""
            return nil
        end
        if did.include?(LOCATION_PREFIX)
            tmp = did.split(LOCATION_PREFIX)
            did = tmp[0]
            did_location = tmp[1]
        end
        
        # setup
        currentDID = {
            "did": did,
            "doc": "",
            "log": [],
            "doc_log_id": nil,
            "termination_log_id": nil,
            "last_id": nil,
            "last_sign_id": nil,
            "error": 0,
            "message": ""
        }.transform_keys(&:to_s)
        did_hash = did.delete_prefix("did:oyd:")
        did10 = did_hash[0,10]

        # get did location
        did_location = ""
        if !options[:doc_location].nil?
            did_location = options[:doc_location]
        end
        if did_location.to_s == ""
            if !options[:location].nil?
                did_location = options[:location]
            end
        end

        # retrieve DID document
        did_document = retrieve_document(did_hash, did10 +  ".doc", did_location, options)
        currentDID["doc"] = did_document

        # retrieve log
        log_array = DidLog.where(did: did).pluck(:item)
        currentDID["log"] = log_array

        # traverse log to get current DID state
        dag = dag_did(log_array)
        currentDID = dag_update(dag.vertices.first, log_array, currentDID)

        return currentDID
    end

    def oyd_encode(message)
        # Base58.encode(message.force_encoding('ASCII-8BIT').unpack('H*')[0].to_i(16))
        Base58.binary_to_base58(message.force_encoding('BINARY'))
    end

    def oyd_decode(message)
        # [Base58.decode(message.force_encoding('ASCII-8BIT')).to_s(16)].pack('H*')
        Base58.base58_to_binary(message)
    end

    def oyd_hash(message)
        oyd_encode(RbNaCl::Hash.sha256(message))
    end

    def dag_did(logs)
        dag = DAG.new
        dag_log = []
        log_hash = []
        i = 0
        dag_log << dag.add_vertex(id: i)
        logs.each do |el|
            log = JSON.parse(el)
            i += 1
            dag_log << dag.add_vertex(id: i)
            log_hash << oyd_hash(log.to_json)
            if log["previous"] == []
                dag.add_edge from: dag_log[0], to: dag_log[i]
            else
                log["previous"].each do |p|
                    position = log_hash.find_index(p)
                    if !position.nil?
                        dag.add_edge from: dag_log[position+1], to: dag_log[i]
                    end
                end
            end
        end unless logs.nil?
        return dag
    end

    def dag_update(vertex, logs, currentDID)
        vertex.successors.each do |v|
            current_log = logs[v[:id].to_i - 1]
            if currentDID["last_id"].nil?
                currentDID["last_id"] = current_log["id"].to_i
            else
                if currentDID["last_id"].to_i < current_log["id"].to_i
                    currentDID["last_id"] = current_log["id"].to_i
                end
            end
            case current_log["op"]
            when 2,3 # CREATE, UPDATE
                doc_did = current_log["doc"]
                doc_location = get_location(doc_did)
                did_hash = doc_did.delete_prefix("did:oyd:")
                did10 = did_hash[0,10]
                doc = retrieve_document(doc_did, did10 + ".doc", doc_location, {})
                # check if sig matches did doc 
                if match_log_did?(current_log, doc)
                    currentDID["doc_log_id"] = v[:id].to_i
                    currentDID["did"] = doc_did
                    currentDID["doc"] = doc
                    if currentDID["last_sign_id"].nil?
                        currentDID["last_sign_id"] = current_log["id"].to_i
                    else
                        if currentDID["last_sign_id"].to_i < current_log["id"].to_i
                            currentDID["last_sign_id"] = current_log["id"].to_i
                        end
                    end
                end
            when 0
                # TODO: check if termination document exists
                currentDID["termination_log_id"] = v[:id].to_i
            end

            if v.successors.count > 0
                currentDID = dag_update(v, logs, currentDID)
            end
        end
        return currentDID
    end

    def match_log_did?(log, doc)
        # check if signature matches current document
        # check if signature in log is correct
        publicKeys = doc["key"]
        pubKey_string = publicKeys.split(":")[0] rescue ""
        pubKey = Ed25519::VerifyKey.new(Base58.base58_to_binary(pubKey_string))
        signature = oyd_decode(log["sig"])
        begin
            pubKey.verify(signature, log["doc"])
            return true
        rescue Ed25519::VerifyError
            return false
        end
    end

    def get_key(filename, key_type)
        begin
            f = File.open(filename)
            key_encoded = f.read
            f.close
        rescue
            return nil
        end
        if key_type == "sign"
            return Ed25519::SigningKey.new(Base58.base58_to_binary(key_encoded))
        else
            return Ed25519::VerifyKey.new(Base58.base58_to_binary(key_encoded))
        end
    end

    def get_location(id)
        if id.include?(LOCATION_PREFIX)
            id_split = id.split(LOCATION_PREFIX)
            return id_split[1]
        else
            return nil
        end
    end

    def retrieve_document(doc_hash, doc_file, doc_location, options)
        @did = Did.find_by_did(doc_hash)
        if !@did.nil?
            doc = JSON.parse(@did.doc) rescue nil
            return doc
        end
        case doc_location
        when /^http/
            return nil
        when "local"
            doc = {}
            begin
                f = File.open(doc_file)
                doc = JSON.parse(f.read) rescue {}
                f.close
            rescue

            end
            if doc == {}
                return nil
            end
        else
            return nil
        end
        return doc
    end
end