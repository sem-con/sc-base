ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
  alias_method :orig_initialize, :initialize

  # Extend database initialization to add our own functions
  def initialize(connection, logger = nil, pool = nil)
    orig_initialize(connection, logger, pool)

    # Initializer for SQLite3 databases
    if connection.is_a? SQLite3::Database
      # Set up function to provide SQLite REGEXP support
      connection.create_function('regexp', 2) do |fn, pattern, expr|
        # Ignore case in our regex expressions
        matcher = Regexp.new(pattern.to_s, Regexp::IGNORECASE)
        # Return 1 if expression matches our regex, 0 otherwise
        fn.result = expr.to_s.match(matcher) ? 1 : 0
      end
    end
  end
end