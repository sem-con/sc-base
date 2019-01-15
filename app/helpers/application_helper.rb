module ApplicationHelper
	def createLog(value)
        Log.new(item: value).save
    end

	def suppress_output
	  begin
	    original_stderr = $stderr.clone
	    original_stdout = $stdout.clone
	    $stderr.reopen(File.new('/dev/null', 'w'))
	    $stdout.reopen(File.new('/dev/null', 'w'))
	    retval = yield
	  rescue Exception => e
	    $stdout.reopen(original_stdout)
	    $stderr.reopen(original_stderr)
	    raise e
	  ensure
	    $stdout.reopen(original_stdout)
	    $stderr.reopen(original_stderr)
	  end
	  retval
	end    
end
