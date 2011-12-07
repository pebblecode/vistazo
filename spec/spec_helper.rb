# spec_helper.rb
ENV['RACK_ENV'] = 'test'

# Include web.rb file
require_relative '../web'
# Include factories.rb file
require_relative '../test/factories.rb'

require 'rspec'
require 'rack/test'
require 'factory_girl'


# Include Rack::Test in all rspec tests
RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  # conf.mock_with :rspec
end

# OmniAuth
OmniAuth.config.test_mode = true

# Helper methods

def http_authorization!
  authorize 'vistazo', 'vistazo'
end

def clean_db!
  MongoMapper.database.collections.each do |coll|
    coll.remove
  end
end