require 'yaml'
require 'omniauth-cas'
module Cul::Omniauth::FileConfigurable
  extend ActiveSupport::Concern
  included do |mod|
    #OmniAuth::Strategies::CAS.configure(mod.cas_configuration_opts)
  end
  module ClassMethods
    def cas_configuration_opts
      @cas_opts ||= begin
        _opts = YAML.load_file(File.join(Rails.root,'config','cas.yml'))[Rails.env] || {}
        _opts = _opts.symbolize_keys
        _opts
      end
      @cas_opts
    end
    def configure_devise_omniauth(config,opts=nil)
      opts ||= cas_configuration_opts
      opts = opts.dup
      provider = opts.delete(:provider)
      config.omniauth provider, opts
    end
  end
end