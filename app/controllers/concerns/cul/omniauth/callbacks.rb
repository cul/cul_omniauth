module Cul::Omniauth::Callbacks
  extend ActiveSupport::Concern
  def cas
    find_user('CAS')
  end
  def saml
    find_user('SAML')
  end
  def wind
    find_user('WIND')
  end

  def ssl
    find_user('ssl')
  end

  def find_user(auth_type)
    find_method = "find_for_#{auth_type.downcase}".to_sym
    current_user ||= User.send(find_method,request.env["omniauth.auth"], current_user)
    affils = ["#{request.env["omniauth.auth"].uid}:users.cul.columbia.edu"]
    affils << "staff:cul.columbia.edu" if current_user.cul_staff?
    affils += (request.env["omniauth.auth"].extra.affiliations || [])
    affiliations(current_user,affils)
    session["devise.roles"] = affils
    if current_user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => auth_type
      sign_in_and_redirect current_user, :event => :authentication
    else
      session["devise.#{auth_type.downcase}_data"] = request.env["omniauth.auth"]
      redirect_to root_url
    end
  end
  def affiliations(user, affils)
  end
  protected :find_user
end