# spec_helper.rb
ENV['RACK_ENV'] = 'test'
require 'rspec'
require 'rack/test'
require 'factory_girl'

# Include web.rb file
begin
  require_relative '../web'
rescue NameError 
  require File.expand_path('../web', __FILE__)
end

# Include factories.rb file
begin
  require_relative '../test/factories.rb'
rescue NameError 
  require File.expand_path('../test/factories.rb', __FILE__)
end

# Include Rack::Test in all rspec tests
RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.mock_with :rspec
end

# Define application for all spec files
def app
  Sinatra::Application
end