# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
require "bundler/setup"

require 'rspec'
require 'rspec/matchers'

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.command_name "spec"
end

require File.expand_path("../../spec/dummy/config/environment.rb",  __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../spec/dummy/db/migrate", __FILE__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path('../../db/migrate', __FILE__)
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.method_defined?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
end

def fixture(filename, mode="r")
  path = File.join(File.dirname(__FILE__),'..','fixtures',filename)
  if block_given?
    open(path, mode) {|io| yield io}
  else
    open(path, mode)
  end
end