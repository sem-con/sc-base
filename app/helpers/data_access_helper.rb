module DataAccessHelper
    def getData(params)
        Store.pluck(:item)
    end
end