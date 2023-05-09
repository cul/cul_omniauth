module Cul
  module Omniauth
    autoload :FailureApp, 'cul/omniauth/failure_app'
    autoload :FileConfigurable, 'cul/omniauth/file_configurable'
    autoload :AbilityProxy, 'cul/omniauth/ability_proxy'
    require "cul/omniauth/engine"
  end
end
