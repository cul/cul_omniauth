module Cul::Omniauth::Abilities
  extend ActiveSupport::Concern
  module Empty
    HASH = {}.freeze
    ARRAY = [].freeze
  end
  def initialize(user=nil, opts={})
    @user = user || User.new
    roles = opts[:roles] || Empty::HASH
    if user
      role_permissions = self.class.config.select do |role,config|
        roles.include?(role) or user.role?(role)
      end
      role_permissions[:'*'] = self.class.config.fetch(:*,Empty::HASH)
      opts = {user_id: user.login}.merge(opts)
    else
      role_permissions = {:'*' => self.class.config.fetch(:*,Empty::HASH)}
    end
    role_permissions.each do |role, config|
      config.fetch(:can,Empty::HASH).each do |action, conditions|
        if conditions.blank?
          can action, :all
        else
          can action, Cul::Omniauth::AbilityProxy do |proxy|
            combine_with = conditions.fetch(:combine_with,:and).to_sym
            r = (combine_with == :and)
            if !!proxy
              conditions.fetch(:if,Empty::HASH).each do |property, comparisons|
                p = value_for_property(proxy, property, opts)
                if combine_with == :and
                  r &= !!p
                  r &= comparisons.detect {|c,v| Comparisons.send(c, p, v)}
                elsif p
                  r ||= comparisons.detect {|c,v| Comparisons.send(c, p, v)}
                end
              end
              conditions.fetch(:unless,Empty::HASH).each do |property, comparisons|
                p = value_for_property(proxy, property, opts)
                if p
                  if combine_with == :and
                    r &= !comparisons.detect {|c,v| Comparisons.send(c, p, v)}
                  else
                    r ||= !comparisons.detect {|c,v| Comparisons.send(c, p, v)}
                  end
                end
              end
            end
            r
          end
        end
      end
    end
  end
  private
  def value_for_property(proxy, property_handle, opts)
    if proxy.respond_to? property_handle.to_sym
      property = proxy.send property_handle
    end
    property = opts.fetch(property_handle,Empty::ARRAY) if property.blank? || property.empty?
    property
  end
  module Comparisons
    def self.include?(context, value)
      context.include? value
    end
    def self.eql?(context, value)
      context.eql? value
    end
    def self.in?(context, value)
      (Array(value) & Array(context)).size > 0 
    end
  end
  public
  module ClassMethods
    def config
      @role_proxy_config ||= begin
        root = (Rails.root.blank?) ? '.' : Rails.root
        path = File.join(root,'config','roles.yml')
        _opts = YAML.load_file(path)
        all_config = _opts.fetch("_all_environments", {})
        env_config = _opts.fetch(Rails.env, {})
        symbolize_hash_keys(all_config.merge(env_config))
      end
    end
    def self.included mod
      mod.config.each do |k,v|
        if v[:includes]
          v[:includes].each do |included|
            Role.role(k).includes(included.to_sym)
          end
        end
      end
    end
    private
    def symbolize_hash_keys(hash)
      hash.symbolize_keys!
      hash.values.select{|v| v.is_a? Hash}.each{|h| symbolize_hash_keys(h)}
      hash
    end
  end
end