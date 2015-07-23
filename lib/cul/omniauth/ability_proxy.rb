module Cul::Omniauth
  class AbilityProxy
    attr_accessor :mime_type, :context, :content_models, :publisher, :remote_ip
    def initialize(opts = {})
      self.mime_type = opts[:mime_type]
      self.context = opts[:context]
      self.content_models = opts[:content_models] || []
      self.publisher = opts[:publisher] || []
      self.remote_ip = opts[:remote_ip] || []
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