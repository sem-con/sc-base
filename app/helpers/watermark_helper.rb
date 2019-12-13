module WatermarkHelper
    require "matrix"
    # def get_fragment(fragment)
    #     size = 100 # fragment size
    #     start = Integer(fragment) rescue 1
    #     if start < 1
    #         start = 1
    #     end
    #     return Store.pluck(:item).first(start*size).last(size)
    # end

    # for myPCH
    def get_fragment(fragment)
        filter_date = Date.parse(fragment) rescue nil
        if filter_date.nil?
            return []
        end
        retVal = []
        Store.pluck(:item).each do |item|
            i = JSON(item)
            if Date.parse(i["time"]) == filter_date
                retVal << i
            end
        end
        return retVal
    end

    # def all_fragments(fragment)
    #     retVal = []
    #     size = 100 # fragment size
    #     [*1 .. (Store.count / size)+1].each { |i| retVal << (i-1)*size+1 }
    #     return retVal
    # end

    # for myPCH
    def all_fragments(fragment)
        retVal = []
        Store.pluck(:item).each { |item| retVal << Date.parse(JSON(item)["time"]).to_s }
        return retVal.uniq

    end

    def get_fragment_key(fragment_id, user_id)
        @wm = Watermark.where(user_id: user_id, fragment: fragment_id)
        if @wm.count == 0
            @wm = Watermark.new(user_id: user_id, 
                      fragment: fragment_id,
                      key: rand(10e8))
            @wm.save
        else
            @wm = @wm.first
        end
        return @wm.key
    end

    def apply_watermark(data, key)
        retVal = []
        ev = error_vector(key, data.length)
        i = 0
        data.each do |item|
            new_item = item.stringify_keys
            new_item["value"] += ev[i]
            retVal << new_item
            i += 1
        end
        return retVal
    end

    def error_scale(error_vector)
        range = 0.4
        max = 0.2
        return (Vector.elements(error_vector)*range).collect { |i| i - (range-max) }.to_a
    end

    def error_vector(seed, error_length)
        srand(seed.to_i)
        retVal = []
        error_length.times{ retVal << rand }
        return error_scale(retVal)
    end

    def valid_user?(user_id)
        Doorkeeper::Application.find(user_id).present? rescue false
    end

    # def valid_fragment?(user_id)
    #     Integer(fragment).present? rescue false
    # end

    # for myPCH
    def valid_fragment?(fragment)
        Date.parse(fragment).present? rescue false
    end

    def distance(x, y)
        require 'enumerable/standard_deviation'
        
        subset = 0..([x.length, y.length].min - 1)
        subset.map { |i| (x[i] - y[i])**2}.mean
    end

end