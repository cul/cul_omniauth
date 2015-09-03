module Cul::Omniauth::Users::ConfiguredRoles
  extend ActiveSupport::Concern
  def role? role_sym
    super || begin
      found = false
      found = role_members(role_sym).detect {|member| self.role?(member.to_sym)}
    end
  end
  def role_members(role_sym)
    Ability.config.fetch(role_sym.to_sym,{}).fetch(:members,[])
  end
end
