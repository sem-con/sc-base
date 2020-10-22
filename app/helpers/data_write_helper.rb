module DataWriteHelper
    def writeData(content, input, provenance, read_hash)
        # write data to container store
        new_items = []
        # begin
            if content.class == String
                if content == ""
                    render plain: "",
                           status: 500
                    return
                end
                content = [content]
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
                my_input = input.first
            else
                my_params = input
                my_input = input.except("id", "dri", "schema_dri", "mime_type")
            end

puts "PARAMS==========="
puts input.to_json
puts "my_params----"
puts my_params.to_json
puts "my_input-----"
puts my_input.to_json
puts "content------"
puts content.to_json
puts "-------------"

            if my_params.nil? || (my_params["id"].to_s == "" && (my_params["p"].to_s == "id" || my_params["p"].to_s == "dri"))
                # write data of new record
                Store.transaction do
                    content.each do |item|
                        case container_format
                        when "RDF", "CSV"
                            my_store = Store.new(item: item, prov_id: prov_id)
                        else
                            dri = nil
                            if item["dri"].to_s != ""
                                dri = item["dri"].to_s
                            end
                            schema_dri = nil
                            if item["schema_dri"].to_s != ""
                                schema_dri = item["schema_dri"].to_s
                            end
                            mime_type = "application/json"
                            if item["mime_type"].to_s != ""
                                mime_type = item["mime_type"].to_s
                            end
                            if item["content"].to_s != ""
                                item = item["content"]
                            end

                            my_store = Store.new(
                                item: item.to_json, 
                                prov_id: prov_id, 
                                dri: dri, 
                                schema_dri: schema_dri, 
                                mime_type: mime_type)
                        end
                        my_store.save
                        new_items << my_store.id
                    end
                end
            else
                # update record
                @item = nil
                if my_params["p"].to_s == "id"
                    @item = Store.find(my_params["id"]) rescue nil
                elsif my_params["p"].to_s == "dri"
                    @item = Store.find_by_dri(my_params["dri"]) rescue nil
                end
                if @item.nil?
                    render json: {"error": "not found"},
                           status: 4040
                    return
                end
                if my_input["content"].to_s == ""
                    @item.update_attributes(item: my_input.to_json)
                else
                    @item.update_attributes(item: my_input["content"].to_json)
                end
                if my_input["dri"].to_s != ""
                    @item.update_attributes(dri: my_input["dri"].to_s)
                end
                if my_input["schema_dri"].to_s != ""
                    @item.update_attributes(schema_dri: my_input["schema_dri"].to_s)
                end
                if my_input["mime_type"].to_s != ""
                    @item.update_attributes(mime_type: my_input["mime_type"].to_s)
                end
                new_items = [@item.id]
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
                          "revocation_key": revocation_key},
                   status: 200

        # rescue => ex
        #     render json: {"error": ex.to_s},
        #            status: 500
        # end
    end
end