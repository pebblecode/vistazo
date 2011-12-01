# spec_helper.rb
ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require 'factory_girl'

# Include factories.rb file
begin
  require_relative '../test/factories.rb'
rescue NameError 
  require File.expand_path('../test/factories.rb', __FILE__)
end

# Include web.rb file
begin
  require_relative '../web'
rescue NameError 
  require File.expand_path('../web', __FILE__)
end

