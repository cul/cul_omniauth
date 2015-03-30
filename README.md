# Cul::Omniauth

Cul::Omniauth is a Rails engine to facilitate using [Devise](https://github.com/plataformatec/devise "Devise") and Omniauth with the [CAS offering from Columbia University IT](https://cuit.columbia.edu/cas-authentication "CUIT CAS Documentation").

These instructions assume the Devise generators have been run for the target application.

## Basic CAS Configuration
```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :cas, host: 'cas.yourdomain.com'
end
```

More CAS configuration information at [OmniAuth CAS](https://github.com/dlindahl/omniauth-cas "OmniAuth-CAS")

## Configuring from a file
CAS configurable with Devise from config/cas.yml by mixin:

```ruby
module MyModule
  class Application < Rails::Application
    include Cul::Omniauth::FileConfigurable
  end
end
```

...then configuring from within the Devise initializer:
```ruby
Devise.setup do |config|
  MyModule::Application.configure_devise_omniauth(config)
end
```

The config file is called cas.yml, and following the [CUIT CAS documentation](https://cuit.columbia.edu/cas-authentication "CUIT CAS Documentation") should be similar to:
```YAML
cas: &CAS
  host: cas.columbia.edu
  login_url: /cas/login
  logout_url: /cas/logout
  service_validate_url: /cas/serviceValidate
  disable_ssl_verification: true
  provider: cas
saml: &SAML
  <<: *CAS
  provider: saml
  service_validate_url: /cas/samlValidate
wind: &WIND
  host: wind.columbia.edu  
  login_url: /login
  logout_url: /logout
  service_validate_url: /validate
  service: 'your_service_key_here'
  provider: wind
```
... with the environment configurations for your Rails app including one of these configurations as appropriate. **If your application uses affiliation attributes from CAS, it must use the :saml provider**.

## Controller Mixins

Using Devise and OmniAuth requires a Sessions controller and a Callbacks controller in the Users namespace.
### Devise/OmniAuth Callbacks Controller
The Callbacks controller should subclass Devise::OmniauthCallbacksController and mixin Cul::Omniauth::Callbacks

```ruby
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Cul::Omniauth::Callbacks
end
```

### Devise Sessions Controller
The Sessions controller should subclass Devise::SessionsController and provide two methods:

```ruby
class Users::SessionsController < Devise::SessionsController
  def new_session_path(scope)
    new_user_session_path # this accomodates Users namespace of the controller
  end

  def omniauth_provider_key
    # there is support for :wind, :cas, and :saml in Cul::Omniauth
  end
end
```

### Authorizing Application Controllers
Once the authentication machinery is configured, users can be authenticated by including the appropriate Devise mixins:
```ruby
class ApplicationController < ActionController::Base
  include Devise::Controllers::Helpers
  devise_group :user, contains: [:user]
  before_filter before_filter :authenticate_user!, if: :devise_controller?
end
```

Authorization is handled by separate libraries, although Cul::Omniauth is currently developed with [CanCan](https://github.com/ryanb/cancan "CanCan") support in mind.

## Model Requirements
This gem assumes use of the Devise sessions model, though your application must still provide a User model. This User model should mixin the Cul::Omniauth::Users module:
```ruby
class User < ActiveRecord::Base
  # Connects this user object to Blacklights Bookmarks and Folders. 
  include Blacklight::User
  include Cul::Omniauth::Users
  # additional application-local business
end
```

If your application is using [CanCan](https://github.com/ryanb/cancan "CanCan") for authorization, it will also need to provide an Ability model similar to:
```ruby
class Ability
  include CanCan::Ability
  def initialize(user)
    @user = user || User.new # default to guest user
  end
end  
```
More information about CanCan is available on the [CanCan Github repository](https://github.com/ryanb/cancan "CanCan").