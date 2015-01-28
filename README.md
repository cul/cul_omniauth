# Cul::Omniauth

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :cas, host: 'cas.yourdomain.com'
end
```

CAS configurable from config/cas.yml by mixin:

```ruby
module MyModule
  class Application < Rails::Application
    include Cul::Omniauth::FileConfigurable
  end
end
```

More CAS configuration information at https://github.com/dlindahl/omniauth-cas

The users controller should subclass Devise::OmniauthCallbacksController and mixin Cul::Omniauth::Callbacks

```ruby
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Cul::Omniauth::Callbacks
end
```