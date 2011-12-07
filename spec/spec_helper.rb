# spec_helper.rb
ENV['RACK_ENV'] = 'test'

# Include web.rb file
require_relative '../web'
# Include factories.rb file
require_relative '../test/factories.rb'

require 'rspec'
require 'rack/test'
require 'factory_girl'
require 'ruby-debug'

# Include Rack::Test in all rspec tests
RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.mock_with :rspec
end

# Helper methods

def http_authorization!
  authorize 'vistazo', 'vistazo'
end

def login!
  OmniAuth.config.test_mode = true
  OmniAuth.config.add_mock(:google_oauth2, {
    :uid => '111965288093828509275',
    :info => {
      :email => "ttt@pebblecode.com",
      :name => 'Tu Tak Tran'
    }
  })
  
  get '/auth/google_oauth2/callback', nil, {"omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2]}
  follow_redirect!
end

def clean_db!
  MongoMapper.database.collections.each do |coll|
    coll.remove
  end
end