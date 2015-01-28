require 'omniauth-cas'
module Cul
  module Omniauth
    autoload :FileConfigurable, 'cul/omniauth/file_configurable'
    require "cul/omniauth/engine"
  end
end
module OmniAuth
  module Strategies
    require 'omni_auth/strategies/wind'
  end
end