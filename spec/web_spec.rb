begin 
  require_relative 'spec_helper'
rescue NameError
  require File.expand_path('spec_helper', __FILE__)
end

include Rack::Test::Methods

def app() Sinatra::Application end

describe "Vistazo authentication" do
  
  it "should work on all pages" do
    all_pages = ['/', '/pebble_code_web_dev', '/pebble_code_web_dev/2011/week/48']
    
    all_pages.each do |page|
      get page
      assert_equal 401, last_response.status
    end
  end
  
end

describe "Vistazo homepage" do
  before do
    authorize 'vistazo', 'vistazo'
  end
  
  after do
    MongoMapper.database.collections.each do |coll|
      coll.remove
    end
  end
  
  it "should return show welcome message" do
    get '/'
    last_response.body.must_include 'Welcome to the Vistazo prototype'
  end
  
  it "should show accounts" do
    Factory(:account, :name => "Fancy web shop")
    Factory(:account, :name => "Software sweets shop")
    
    get '/'
    
    last_response.body.must_include "Fancy web shop"
    last_response.body.must_include "Software sweets shop"
  end
  
end