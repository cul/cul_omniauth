$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "cul/omniauth/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "cul_omniauth"
  s.version     = Cul::Omniauth::VERSION
  s.require_paths = ["lib"]
  s.authors     = ["barmintor"]
  s.email       = ["LASTNAME at gmail"]
  s.homepage    = "https://github.com/cul/cul_omniauth"
  s.summary     = "Omniauth engine for CUL web apps."
  s.description = "Engine and model mixins for Omniauth with CAS and SSL."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 5.0"
  s.add_dependency "devise-guests", "~> 0.3"
  s.add_dependency "omniauth-cas"
  s.add_dependency "cancan"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency 'rspec', '~> 3.5'
end
