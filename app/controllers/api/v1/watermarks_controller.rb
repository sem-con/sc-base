module Api
    module V1
        class WatermarksController < ApiController
            include WatermarkHelper

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            # GET /api/data/fragment/:fragment_id
            # return specified (watermarked) data fragment
            def user_fragment
                user_id = doorkeeper_token.application_id
                fragment_id = params[:fragment_id].to_s rescue nil
                if !valid_fragment?(fragment_id)
                    render json: {"error": "invalid fragment_id"}.to_json,
                           status: 422
                    return
                end

                key = get_fragment_key(fragment_id, user_id)
                data = get_fragment(fragment_id)
                retVal = apply_watermark(data, key)
                render json: retVal, 
                       status: 200
            end

            # GET /api/watermark/user/:user_id
            # return all data watermarked for the specified user
            def user_data
                user_id = params[:user_id].to_i rescue nil
                if !valid_user?(user_id)
                    render json: {"error": "invalid user_id"}.to_json,
                           status: 422
                    return
                end
                retVal = []
                all_fragments("").each do |fragment_id|
                    key = get_fragment_key(fragment_id, user_id)
                    data = get_fragment(fragment_id)
                    retVal += apply_watermark(data, key)
                end
                render json: retVal, 
                       status: 200
            end

            # GET /api/watermark/user/:user_id/fragment/:fragment_id
            # return specified watermarked data fragment for given user
            def user_fragment_data
                user_id = params[:user_id].to_i rescue nil
                if !valid_user?(user_id)
                    render json: {"error": "invalid user_id"}.to_json,
                           status: 422
                    return
                end

                fragment_id = params[:fragment_id].to_s rescue nil
                if !valid_fragment?(fragment_id)
                    render json: {"error": "invalid fragment_id"}.to_json,
                           status: 422
                    return
                end

                key = get_fragment_key(fragment_id, user_id)
                data = get_fragment(fragment_id)
                retVal = apply_watermark(data, key)
                render json: retVal, 
                       status: 200
            end

            # GET /api/watermark/user/:user_id/fragment/:fragment_id/error
            # return error vector for specified fragment and user
            def user_fragment_error
                user_id = params[:user_id].to_i rescue nil
                if !valid_user?(user_id)
                    render json: {"error": "invalid user_id"}.to_json,
                           status: 422
                    return
                end

                fragment_id = params[:fragment_id].to_s rescue nil
                if !valid_fragment?(fragment_id)
                    render json: {"error": "invalid fragment_id"}.to_json,
                           status: 422
                    return
                end

                key = get_fragment_key(fragment_id, user_id)
                data = get_fragment(fragment_id)
                retVal = error_vector(key, data)
                render json: retVal.to_json, 
                       status: 200
            end

            # GET /api/watermark/user/:user_id/fragment/:fragment_id/kpi/:kpi
            # return error vector for specified fragment and user
            def user_fragment_kpi
                require 'enumerable/standard_deviation'

                user_id = params[:user_id].to_i rescue nil
                if !valid_user?(user_id)
                    if user_id.to_s != "0"
                        render json: {"error": "invalid user_id"}.to_json,
                               status: 422
                        return
                    end
                end

                fragment_id = params[:fragment_id].to_s rescue nil
                if !valid_fragment?(fragment_id)
                    render json: {"error": "invalid fragment_id"}.to_json,
                           status: 422
                    return
                end

                data = get_fragment(fragment_id)
                if user_id.to_s != "0"
                    key = get_fragment_key(fragment_id, user_id)
                    data = apply_watermark(data, key)
                end
                vals = data.map { |i| i["value"] }

                case params[:kpi].to_s
                when "mean"
                    retVal = {"mean": vals.mean}
                when "stdv"
                    retVal = {"standard deviation": vals.standard_deviation}
                else
                    render json: {"error": "unknown kpi"}.to_json,
                           status: 404
                    return
                end
                render json: retVal.to_json, 
                       status: 200
            end

            # GET /api/watermark/error/:key(/:len)
            # return error vector for specified key and optional length
            def key
                if params[:len].to_s == ""
                    key_length = 100
                else
                    key_length = Integer(params[:len].to_s) rescue 100
                end
                retVal = error_vector(params[:key].to_s, key_length.times.map{1})
                render json: retVal.to_json, 
                       status: 200
            end

            # GET /api/watermark/fragments
            # return list of fragment identifiers, associated keys, and user_id
            def fragments_list
                retVal = Watermark.select(:user_id, :fragment, :key).order("user_id ASC, fragment ASC").to_json(:except => :id)
                render json: retVal, 
                       status: 200
            end

            # GET /api/watermark/fragment/:fragment_id
            # return specified (not watermarked) data fragment
            def raw_data
                retVal = get_fragment(params[:fragment_id].to_s)
                render json: retVal.to_json, 
                       status: 200
            end

            # POST /api/watermark/identify
            # body: one fragment of a suspicious dataset
            # return descending sorted list of fragment identifiers with distance for each value
            def identify
                input = JSON(request.body.read) rescue nil
                if input.nil?
                    render json: {"error": "invalid JSON"},
                           status: 422
                    return
                end
                input_vals = input.map { |i| i["value"] }
                retVal = []
                all_fragments("").each do |fragment_id|
                    fragment_vals = get_fragment(fragment_id).map { |i| i["value"] }
                    dist, similarity = distance(input_vals, fragment_vals) 
                    retVal << { "fragment": fragment_id, 
                                "size": fragment_vals.length,
                                "distance": dist,
                                "similarity": similarity }
                end
                render json: { "input": {"size": input_vals.length},
                               "identify": retVal.sort_by { |i| i[:distance] } }, 
                       status: 200
            end

            # POST /api/watermark/user/:user_id/fragment/:fragment_id 
            # body: one fragment of a suspicious dataset
            # return distance between provided fragment and watermarked fragment
            def compare
                input = JSON(request.body.read) rescue nil
                if input.nil?
                    render json: {"error": "invalid JSON"},
                           status: 422
                    return
                end
                input_vals = input.map { |i| i["value"] }

                user_id = params[:user_id].to_i rescue nil
                if !valid_user?(user_id)
                    if user_id.to_s != "0"
                        render json: {"error": "invalid user_id"}.to_json,
                               status: 422
                        return
                    end
                end
                fragment_id = params[:fragment_id].to_s rescue nil
                if !valid_fragment?(fragment_id)
                    render json: {"error": "invalid fragment_id"}.to_json,
                           status: 422
                    return
                end
                data = get_fragment(fragment_id)
                if user_id.to_s != "0"
                    key = get_fragment_key(fragment_id, user_id)
                    data = apply_watermark(data, key)
                end
                fragment_vals = data.map { |i| i["value"] }

                dist, similarity = distance(input_vals, fragment_vals)
                retVal = {
                    "input": {
                        "size": input_vals.length,
                    },
                    "fragment": {
                        "id": fragment_id,
                        "size": fragment_vals.length,
                        "distance": dist,
                        "similarity": similarity
                    }
                }
                render json: retVal, 
                       status: 200

            end
        end
    end
end