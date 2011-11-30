# spec_helper.rb
ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require 'factory_girl'

# Include web.rb file
begin
  require_relative '../web'
rescue NameError 
  require File.expand_path('../web', __FILE__)
end

