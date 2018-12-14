module ApplicationHelper
	def createLog(value)
        Log.new(item: value).save
    end
end
