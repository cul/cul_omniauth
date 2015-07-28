module Cul::Omniauth
  class AbilityProxy
    attr_accessor :mime_type, :context, :content_models, :publisher, :remote_ip, :user_id, :user_roles
    def initialize(opts = {})
      self.mime_type = opts[:mime_type]
      self.context = opts[:context]
      self.content_models = opts[:content_models] || []
      self.publisher = opts[:publisher] || []
      self.remote_ip = opts[:remote_ip] || []
      self.user_id = opts[:user_id] || []
      self.user_roles = opts[:user_roles] || []
    end
    def to_h
      return {
        mime_type: mime_type(),
        context: context(),
        content_models: content_models(),
        publisher: publisher(),
        remote_ip: remote_ip()
      }
    end
  end
end