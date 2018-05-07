# Cul::Omniauth

Cul::Omniauth is a Rails engine to facilitate using [Devise](https://github.com/plataformatec/devise "Devise") and Omniauth with the [CAS offering from Columbia University IT](https://cuit.columbia.edu/cas-authentication "CUIT CAS Documentation").

## Versions
__v0.5.3__ is the last version to work with Rails 4, any fixes to this version can be started from `0.x-stable`

__v1.0.0__ is the first version to work with Rails 4, any fixes to this version can be started from `master`


## Installing Devise
1. Add gem 'devise' to Gemfile

2. Run `bundle install`

3. Run devise generator `rails generate devise:install` and follow devise specified instructions

4. Add model, run `rails g model User`

* Check Devise README for latest installation instructions

## Install cul_omniauth

1. Add gem cul_omniauth to Gemfile

2. Run `bundle install`

3. Change mixin in User model to `include Cul::Omniauth::Users`

4. Create migration to remove encrypted_password field of user model

5. Create migration to add uid and provider fields to user model, both are strings

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

development: *CAS
test: *CAS
myapp_dev: *CAS
mypp_test: *CAS
myapp_prod: *CAS
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
## Routing

To ensure that devise uses the proper routes and controllers, change `devise_for :users` to:

`devise_for :users, controllers: {sessions: 'users/sessions', omniauth_callbacks: 'users/omniauth_callbacks'}`

In order to add sign_in and sign_out methods:

```ruby
  devise_scope :user do
    get 'sign_in', :to => 'users/sessions#new', :as => :new_user_session
    get 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session
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

### Troubleshooting

If your user model is not using database authenticatable and does not have a password column, you will need to add two dummy password methods (a getter and a setter). These methods are required by devise. You are having this problem if your user model can't find a password method. To solve this problem add the following methods to your model:

```ruby
def password
  Devise.friendly_token[0,20]
end

def password=(*val)
  # NOOP
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
