module Cul::Omniauth::Users
  extend ActiveSupport::Concern

  included do |mod|
    # Include default devise modules and the omniauthable module
    # Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    mod.devise :registerable, :recoverable, 
    :rememberable, :trackable, :validatable, :omniauthable

    #mod.attr_accessible :username, :uid, :provider
    #mod.attr_accessible :email, :guest
  
    mod.delegate :can?, :cannot?, :to => :ability
  end

  def role? role_sym
    role_sym == :guest
  end

  def ability
    @ability ||= Ability.new(self)
  end

  module ClassMethods
    def find_for_cas(token, resource=nil)
      user = where(:login => token.uid).first
      # create new user if necessary
      unless user
        user = create(whitelist(:login => token.uid))
        # can we add groups or roles here?
      end
      user
    end

    def find_for_saml(token, resource=nil)
      user = where(:login => token.uid).first
      # create new user if necessary
      unless user
        user = create(whitelist(:login => token.uid))
        # can we add groups or roles here?
      end

      user
    end

    def find_for_wind(token, resource=nil)
      user = where(:login => token.uid).first
      # create new user if necessary
      unless user
        user = create(whitelist(:login => token.uid))
        # can we add groups or roles here?
      end

      user
    end

    def from_omniauth(auth)
      where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
        user.email = auth.info.email
        user.password = Devise.friendly_token[0,20]
        user.name = auth.info.name   # assuming the user model has a name
        user.image = auth.info.image # assuming the user model has an image
      end
    end

    private
    def whitelist(params=nil)
      params.permit(:login,:uid,:provider,:email,:guest) if params.respond_to? :permit
      params || {}
    end
  end
end