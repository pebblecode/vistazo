# spec_helper.rb
ENV['RACK_ENV'] = 'test'

# Include web.rb file
require_relative '../web'
# Include factories.rb file
require_relative '../spec/factories.rb'

require 'rspec'
require 'rack/test'
require 'factory_girl'
require 'ruby-debug'
require 'capybara/rspec'

require 'omniauth_spec_helper'
require 'mongodb_spec_helper'
require 'path_spec_helper'

# Include Rack::Test in all rspec tests
RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.mock_with :rspec
  
  conf.include OmniauthSpecHelper
  conf.include MongoDBSpecHelper
  conf.include PathSpecHelper
end

# Helper methods

def http_authorization!
  authorize 'vistazo', 'vistazo'
end
