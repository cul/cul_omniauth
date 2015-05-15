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
      fetch_raw_info = opts.delete(:fetch_raw_info)
      fetch_raw_info = fetch_raw_info.to_sym if fetch_raw_info.is_a? String
      if fetch_raw_info.is_a? Symbol
        method = fetch_raw_info
        fetch_raw_info = lambda do |strategy, options, ticket, ticket_user_info|
          send(method, strategy, options, ticket, ticket_user_info)
        end
      end
      opts[:fetch_raw_info] = fetch_raw_info if fetch_raw_info
      config.omniauth provider, opts
      config.warden do |manager|
        manager.failure_app = Cul::Omniauth::FailureApp.for(provider)
      end
    end
    def print_raw_info(strategy, options, ticket, ticket_user_info)
      puts "strategy: #{strategy.inspect}"
      puts "options: #{options.inspect}"
      puts "ticket: #{ticket.inspect}"
      puts "ticket_user_info: #{ticket_user_info.inspect}"
      {} # for merge
    end
  end
end