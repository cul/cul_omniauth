require 'devise'
class Cul::Omniauth::FailureApp < Devise::FailureApp
  DEFAULT_PROVIDER = :saml
  def self.provider=(provider)
    @provider = provider
  end
  def self.provider
    @provider || DEFAULT_PROVIDER
  end
  def self.for(provider=nil)
  	r = Class.new(self)
  	r.provider = provider || self.provider
  	r
  end
  def redirect_url
    user_omniauth_authorize_path(self.class.provider)
  end
end