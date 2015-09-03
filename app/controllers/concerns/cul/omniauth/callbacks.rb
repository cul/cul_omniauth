module Cul::Omniauth::Callbacks
  extend ActiveSupport::Concern

  OMNIAUTH_REQUEST_KEY = 'omniauth.auth'.freeze

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
    # omniauth puts a hash of information with string keys in the request env
    oa_data = request.env.fetch(OMNIAUTH_REQUEST_KEY,{})
    @current_user ||= User.send(find_method,oa_data, @current_user)
    affils = ["#{oa_data['uid']}:users.cul.columbia.edu"]
    affils << "staff:cul.columbia.edu" if @current_user.respond_to?(:cul_staff?) and @current_user.cul_staff?
    affils += (oa_data.fetch('extra',{})['affiliations'] || [])
    affiliations(@current_user,affils)
    session["devise.roles"] = affils
    if @current_user && @current_user.persisted?
      message = I18n.t "devise.omniauth_callbacks.success", kind: auth_type
      flash[:notice] = message unless message.blank?
      sign_in_and_redirect @current_user, :event => :authentication
    else
      reason = @current_user ? 'no persisted user for id' : 'no uid in token'
      Rails.logger.warn("#{reason} #{oa_data.inspect}")
      flash[:notice] = I18n.t "devise.omniauth_callbacks.failure", kind: auth_type, reason: reason
      session["devise.#{auth_type.downcase}_data"] = oa_data
      redirect_to root_url
    end
  end

  def affiliations(user, affils)
  end

  def after_sign_in_path_for(resource)
    session[:return_to] || super
  end

  protected :find_user
end