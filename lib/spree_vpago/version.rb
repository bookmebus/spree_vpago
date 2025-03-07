module SpreeVpago
  module_function

  VERSION = '1.0.0-spree-4.5'.freeze

  def version
    Gem::Version.new VERSION
  end
end
