module Cul::Omniauth::RemoteIpAbility
  extend ActiveSupport::Concern
  def current_ability
    @current_ability ||= Ability.new(current_user, remote_ip:request.remote_ip)
  end
end