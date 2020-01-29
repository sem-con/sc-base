module DataAccessHelper
    include WatermarkHelper

    def getData(params)
        if ENV["WATERMARK"].to_s == ""
            Store.pluck(:item)
        else
            retVal = []
            all_fragments("").each do |fragment_id|
                key = get_fragment_key(fragment_id, doorkeeper_token.application_id)
                data = get_fragment(fragment_id)
                retVal += apply_watermark(data, key)
            end
            return retVal
        end
    end

    def get_provision(params, logstr)
        retVal_type = container_format
        timeStart = Time.now.utc
        retVal_data = getData(params)
        timeEnd = Time.now.utc
        content = []
        case retVal_type.to_s
        when "JSON"
            if retVal_data.first.is_a? String 
                retVal_data.each { |item| content << JSON(item) } rescue nil
            else
                content = retVal_data
            end
            content_hash = Digest::SHA256.hexdigest(content.to_json)
        when "RDF"
            retVal_data.each { |item| content << item.to_s }
            content_hash = Digest::SHA256.hexdigest(content.to_s)
        else
            content = retVal_data.join("\n")
            content_hash = Digest::SHA256.hexdigest(content.to_s)
        end
        param_str = request.query_string.to_s

        createLog({
            "type": logstr,
            "scope": "all (" + retVal_data.count.to_s + " records)"})

        {
            "content": content,
            "usage-policy": container_usage_policy.to_s,
            "provenance": getProvenance(content_hash, param_str, timeStart, timeEnd)
        }.stringify_keys
    end

end