module SpreeVpago
  module_function

  # Returns the version of the currently loaded SpreeVpago as a
  # <tt>Gem::Version</tt>.
  def version
    Gem::Version.new VERSION::STRING
  end

  module VERSION
    MAJOR = 0
    MINOR = 1
    TINY  = 10
    # PRE   = 'alpha'.freeze

    # STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
    STRING = [MAJOR, MINOR, TINY].compact.join('.')
  end
end
