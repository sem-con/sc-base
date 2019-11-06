module DataWriteHelper
    def writeData(content, input, provenance)
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
            prov = Provenance.new(
                prov: provenance, 
                input_hash: Digest::SHA256.hexdigest(input.to_json),
                startTime: Time.now.utc)
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

            Provenance.find(prov_id).update_attributes(
                endTime: Time.now.utc)

            createLog({
                "type": "write",
                "scope": new_items.to_s,
                "request": request.remote_ip.to_s}.to_json)
            render plain: "",
                   status: 200

        rescue => ex
            puts "Error: " + ex.to_s
            render plain: "",
                   status: 500
        end
    end
end