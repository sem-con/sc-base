module Api
    module V1
        class ReceiptsController < ApiController
            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def index
                render json: Provenance.pluck(:receipt_hash).reject(&:blank?),
                       status: 200
            end

            def show
                if params[:ttl].to_s == ""
                    ttl = 0
                else
                    ttl = params[:ttl].to_i rescue 0
                end
                @prov = Provenance.find_by_receipt_hash(params[:id].to_s)
                if @prov.nil?
                    render json: {"error": "not found"},
                           status: 404
                    return
                end

                # get list of item_ids (scope)
                item_ids = JSON.parse(@prov.scope)

                # iterate over Log and check for all read requests that include item_ids
                # on match: add to receipt_list
                receipt_list = []
                Log.all.each do |item|
                    item_hash = JSON.parse(item.item)
                    if item_hash["type"].to_s.starts_with?("read")
                        ids = JSON.parse(item_hash["scope"])
                        if !(item_ids & ids).empty?
                            receipt_list << JSON.parse(item.receipt) unless item.receipt.blank?
                        end
                    end
                end

                retVal = []
                # iterate over receipt-list
                receipt_list.each do |item|
                    if ttl > 0
                        # get receipt from service-endpoint/receipt_hash
                        if params[:short].to_s == ""
                            receipt_url = item["serviceEndpoint"].to_s + "/api/receipt/" + (ttl-1).to_s + "/" + item["receipt"].to_s
                        else
                            receipt_url = item["serviceEndpoint"].to_s + "/api/rcpt/" + (ttl-1).to_s + "/" + item["receipt"].to_s
                        end
                        begin
                            response = HTTParty.get(receipt_url, timeout: 5)
                            # and add response to return Value 
                            retVal << response.parsed_response
                        rescue # Net::ReadTimeout
                            retVal << item
                        end
                    else
                        retVal << item
                    end
                end

                if params[:short].to_s == ""
                    render json: {
                                    "input_hash": @prov.input_hash,
                                    "ids": item_ids,
                                    "timestamp": @prov.startTime,
                                    "uid": Semantic.first.uid.to_s,
                                    "requests": retVal
                                 }, 
                           status: 200
                else
                    render json: {
                                    "input_hash": @prov.input_hash,
                                    "timestamp": @prov.startTime,
                                    "uid": Semantic.first.uid.to_s,
                                    "requests": retVal
                                 }, 
                           status: 200
                end
            end

            def create
                if params[:id].to_s == ""
                    read_hash = params["read_hash"].to_s
                else
                    read_hash = params[:id].to_s
                end
                @log = Log.find_by_read_hash(read_hash)
                if @log.nil?
                    render json: {"error": "not found"},
                           status: 404
                else
                    @log.update_attributes(receipt: params.except("format", "controller", "action", "id", "read_hash").to_json)
                    render plain: "",
                           status: 200
                end
            end
        end
    end
end