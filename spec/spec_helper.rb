# spec_helper.rb
ENV['RACK_ENV'] = 'test'

# Include web.rb file
require_relative '../web'
# Include factories.rb file
require_relative 'support/factories.rb'

require 'rspec'
require 'rack/test'
require 'factory_girl'
require 'ruby-debug'
require 'capybara/rspec'
require 'email_spec'

require 'support/omniauth'
require 'support/mongodb'
require 'support/path'

# Include Rack::Test in all rspec tests
RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.mock_with :rspec
  
  conf.include(EmailSpec::Helpers)
  conf.include(EmailSpec::Matchers)
  
  conf.include OmniauthSpecHelper
  conf.include MongoDBSpecHelper
  conf.include PathSpecHelper
end

Capybara.save_and_open_page_path = "./tmp"

# Helper methods

def http_authorization!
  authorize 'vistazo', 'vistazo'
end

def http_authorization_capybara!
  auth_string = ActiveSupport::Base64.encode64("vistazo:vistazo").gsub(/ /, '')
  driver = Capybara.current_session.driver
  driver.header "Authorization", "Basic #{auth_string}"
end

# Define application for all spec files
def app
  Sinatra::Application
end
Capybara.app = VistazoApp