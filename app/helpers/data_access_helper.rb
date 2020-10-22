module DataAccessHelper
    include WatermarkHelper

    def getData(params)
        if ENV["WATERMARK"].to_s == ""
            if params.to_s.starts_with?("id=")
                [Store.select(:id, :item, :dri, :schema_dri).find(params[3..-1])].map(&:serializable_hash) rescue []
            elsif params.to_s.starts_with?("dri=")
                [Store.select(:id, :item, :dri, :schema_dri).find_by_dri(params[4..-1])].map(&:serializable_hash) rescue []
            elsif params.to_s.starts_with?("schema_dri=")
                [Store.select(:id, :item, :dri, :schema_dri).find_by_schema_dri(params[11..-1])].map(&:serializable_hash) rescue []
            else
                Store.select(:id, :item, :dri, :schema_dri).to_a.map(&:serializable_hash)
            end
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
        if (params[:p].to_s == "id")
            retVal_data = getData("id=" + params[:id].to_s)
        elsif (params[:p].to_s == "dri")
            retVal_data = getData("dri=" + params[:id].to_s)
        elsif (params["schema_dri"].to_s != "")
            retVal_data = getData("schema_dri=" + params["schema_dri"].to_s)
        elsif !(Date.parse(params[:id].to_s) rescue nil).nil?
            retVal_data = getData("day=" + params[:id].to_s)
        else
            retVal_data = getData(params[:id].to_s)
        end
        if retVal_data.nil?
            retVal_data = []
        end
        timeEnd = Time.now.utc
        content = []
        case retVal_type.to_s
        when "JSON"
            if retVal_data.count > 0
                retVal_data.each do |el| 
                    if el["item"].is_a? String
                        val = {"content": JSON(el["item"])}.stringify_keys
                    else
                        val = {"content": el["item"]}.stringify_keys
                    end
                    val["id"] = el["id"]
                    if el["dri"].to_s != ""
                        val["dri"] = el["dri"].to_s
                    end
                    if el["schema_dri"].to_s != ""
                        val["schema_dri"] = el["schema_dri"].to_s
                    end
                    content << val.stringify_keys
                end
            end
            content_hash = Digest::SHA256.hexdigest(content.to_json)
        when "RDF"
            retVal_data.each { |el| content << el["item"].to_s }
            content_hash = Digest::SHA256.hexdigest(content.to_s)
        else
            content = ""
            retVal_data.each { |el| content += el["item"].to_s + "\n" }
            content_hash = Digest::SHA256.hexdigest(content.to_s)
        end
        param_str = request.query_string.to_s

        cup = container_usage_policy.to_s
        if params[:p].to_s == ""
            retVal = {
                "data": content,
                "provenance": getProvenance(content_hash, param_str, timeStart, timeEnd)
            }.stringify_keys
            if cup.to_s != ""
                retVal["usage-policy"] = cup
            end
        else
            if content == [] || content == ""
                retVal = content
            else
                retVal = content.first
                if cup.to_s != ""
                    retVal["usage-policy"] = cup
                end
                retVal["provenance"] = getProvenance(content_hash, param_str, timeStart, timeEnd)
            end
        end

        createLog({
            "type": logstr,
            "scope": retVal_data.map{|h| h["id"]}.flatten.sort.to_json}, # "all (" + retVal_data.count.to_s + " records)"},
            Digest::SHA256.hexdigest(retVal.to_json))

        return retVal
    end
end