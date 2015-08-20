module Cul::Omniauth::Users
  extend ActiveSupport::Concern

  included do |mod|
    # Include default devise modules and the omniauthable module
    # Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    mod.devise :registerable, :recoverable, 
    :rememberable, :trackable, :validatable, :omniauthable

    #mod.attr_accessible :password
    #mod.attr_accessible :username, :uid, :provider
    #mod.attr_accessible :email, :guest
  
    mod.delegate :can?, :cannot?, :to => :ability
  end


  def full_name
    return self.first_name + ' ' + self.last_name
  end

  def role? role_sym
    role_sym == :*
  end

  def ability
    @ability ||= Ability.new(self)
  end

  module ClassMethods
    # token is an omniauth hash
    def find_for_provider(token, provider)
      return nil unless token['uid']
      props = {:uid => token['uid'].downcase, provider: provider.downcase}
      user = where(props).first
      # create new user if necessary
      unless user
        user = create!(whitelist(props))
        # can we add groups or roles here?
      end
      user
    end
    def find_for_cas(token, resource=nil)
      find_for_provider(token, 'cas')
    end

    def find_for_saml(token, resource=nil)
      find_for_provider(token, 'saml')
    end

    def find_for_wind(token, resource=nil)
      find_for_provider(token, 'wind')
    end

    def from_omniauth(auth)
      where(provider: token['provider'].downcase, uid: token['uid'].downcase).first_or_create do |user|
        user.email = token['info']['email']
        user.password = Devise.friendly_token[0,20]
      end
    end

    private
    def whitelist(params=nil)
      params.permit(:uid,:provider,:email,:guest) if params.respond_to? :permit
      params || {}
    end
  end
end