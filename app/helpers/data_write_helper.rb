module DataWriteHelper
    def writeData(content, input, provenance, read_hash)
        # write data to container store
        new_items = []
        # begin
            if input.class == String
                if input == ""
                    render plain: "",
                           status: 500
                    return
                end
                input = [input]
            end

            # write provenance
            # input_hash = read_hash / Digest::SHA256.hexdigest(input.to_json)
            prov_timestamp = Time.now.utc
            prov = Provenance.new(
                prov: provenance, 
                input_hash: read_hash,
                startTime: prov_timestamp)
            prov.save
            prov_id = prov.id

            if input.is_a?(Array)
                my_params = input.drop(1).first
                # my_input = input.first
            else
                my_params = input
                # my_input = input # .except("id", "dri", "schema_dri", "mime_type")
            end
            if my_params.nil?
                my_params = {}
            end

            if my_params["id"].to_s != "" && (my_params["p"].to_s == "id" || my_params["p"].to_s == "dri")
                # update record
                @item = nil
                if my_params["p"].to_s == "id"
                    @item = Store.find(my_params["id"]) rescue nil
                elsif my_params["p"].to_s == "dri"
                    @item = Store.find_by_dri(my_params["dri"]) rescue nil
                end
                if @item.nil?
                    render json: {"error": "not found"},
                           status: 404
                    return
                end
                if input["content"].to_s == ""
                    @item.update_attributes(item: input.to_json)
                else
                    @item.update_attributes(item: input["content"].to_json)
                end
                if input["dri"].to_s != ""
                    @item.update_attributes(dri: input["dri"].to_s)
                end
                if input["schema_dri"].to_s != ""
                    @item.update_attributes(schema_dri: input["schema_dri"].to_s)
                end
                if input["mime_type"].to_s != ""
                    @item.update_attributes(mime_type: input["mime_type"].to_s)
                end
                if input["tale_name"].to_s != ""
                   @item.update_attributes(table_name: input["table_name"].to_s) 
                end
                new_items = [@item.id]
            else
                # write data of new record
                if input.class == Hash
                    input = [input]
                end
                Store.transaction do
                    input.each do |item|
                        case container_format
                        when "RDF", "CSV"
                            @record = Store.new(item: item, prov_id: prov_id)
                            @record.save
                        else
                            dri = nil
                            if item["dri"].to_s != ""
                                dri = item["dri"].to_s
                            end
                            @record = Store.find_by_dri(dri)
                            if dri.nil? || @record.nil?
                                schema_dri = nil
                                if item["schema_dri"].to_s != ""
                                    schema_dri = item["schema_dri"].to_s
                                end
                                if item["table_name"].to_s != ""
                                    table_name = item["table_name"].to_s
                                end
                                mime_type = "application/json"
                                if item["mime_type"].to_s != ""
                                    mime_type = item["mime_type"].to_s
                                end
                                if item["content"].to_s != ""
                                    item = item["content"]
                                end
                                @record = Store.new(
                                    item: item.to_json, 
                                    prov_id: prov_id, 
                                    dri: dri, 
                                    schema_dri: schema_dri, 
                                    mime_type: mime_type,
                                    table_name: table_name)
                                @record.save
                            else                                
                                if item["schema_dri"].to_s != ""
                                    @record.update_attributes(schema_dri: item["schema_dri"].to_s)
                                end
                                if item["table_name"].to_s != ""
                                    @record.update_attributes(table_name: item["table_name"].to_s)
                                end
                                if item["mime_type"].to_s != ""
                                    @record.update_attributes(mime_type: item["mime_type"].to_s)
                                end
                                if item["content"].to_s != ""
                                    @record.update_attributes(item: item["content"].to_json)
                                else
                                    @record.update_attributes(item: item.to_json)
                                end
                            end
                        end
                        new_items << @record.id
                    end
                end                
            end

            # create receipt information
            receipt_json = createReceipt(read_hash, new_items, prov_timestamp)
            receipt_hash = Digest::SHA256.hexdigest(receipt_json.to_json)

            # finalize provenance
            revocation_key = SecureRandom.hex(16).to_s
            Provenance.find(prov_id).update_attributes(
                scope: new_items.to_s,
                receipt_hash: receipt_hash.to_s,
                revocation_key: revocation_key,
                endTime: Time.now.utc,
                input_hash: read_hash)

            # write Log
            createLog({
                "type": "write",
                "scope": new_items.to_s})

            render json: {"receipt": receipt_hash.to_s,
                          "serviceEndpoint": ENV["SERVICE_ENDPOINT"].to_s,
                          "read_hash": read_hash,
                          "revocationKey": revocation_key},
                   status: 200

        # rescue => ex
        #     render json: {"error": ex.to_s},
        #            status: 500
        # end
    end
end