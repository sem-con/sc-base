module DataWriteHelper
    def writeData(content, input, provenance, read_hash)
        # write data to container store
        new_items = []
        begin
            if content.class == String
                if content == ""
                    render plain: "",
                           status: 500
                    return
                end
                content = [content]
            end

            # write provenance
            input_hash = Digest::SHA256.hexdigest(input.to_json)
            prov_timestamp = Time.now.utc
            prov = Provenance.new(
                prov: provenance, 
                input_hash: input_hash,
                startTime: prov_timestamp)
            prov.save
            prov_id = prov.id

            # write data
            Store.transaction do
                content.each do |item|
                    case container_format
                    when "RDF", "CSV"
                        my_store = Store.new(item: item, prov_id: prov_id)
                    else
                        my_store = Store.new(item: item.to_json, prov_id: prov_id)
                    end
                    my_store.save
                    new_items << my_store.id
                end
            end

            # create receipt information
            receipt_json = createReceipt(input_hash, new_items, prov_timestamp)
            receipt_hash = Digest::SHA256.hexdigest(receipt_json.to_json)

            # finalize provenance
            revocation_key = SecureRandom.hex(16).to_s
            Provenance.find(prov_id).update_attributes(
                scope: new_items.to_s,
                receipt_hash: receipt_hash.to_s,
                revocation_key: revocation_key,
                endTime: Time.now.utc)

            # write Log
            createLog({
                "type": "write",
                "scope": new_items.to_s})

            render json: {"receipt": receipt_hash.to_s,
                          "serviceEndpoint": ENV["SERVICE_ENDPOINT"].to_s,
                          "read_hash": read_hash,
                          "revocation_key": revocation_key},
                   status: 200

        rescue => ex
            render json: {"error": ex.to_s},
                   status: 500
        end
    end
end