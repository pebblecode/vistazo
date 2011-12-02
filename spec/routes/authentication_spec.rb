begin 
  require_relative '../spec_helper'
rescue NameError
  require File.expand_path('../spec_helper', __FILE__)
end

include Rack::Test::Methods

def app() Sinatra::Application end

describe "Vistazo HTTP authentication" do

  it "should be on all pages" do
    all_pages = ['/', '/pebble_code_web_dev', '/pebble_code_web_dev/2011/week/48']
  
    all_pages.each do |page|
      get page
      assert_equal 401, last_response.status
    end
  end

end

describe "Vistazo Google sign in" do
  before do
    http_login
  end
  
  it "should show sign in link on homepage" do
    get '/'
    last_response.body.must_include 'Start using Vistazo'
  end
end