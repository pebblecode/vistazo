begin 
  require_relative '../spec_helper'
rescue NameError
  require File.expand_path('../spec_helper', __FILE__)
end

include Rack::Test::Methods

def app() Sinatra::Application end

describe "Vistazo homepage" do
  before do
    http_login
  end
  
  after do
    clear_database
  end
  
  it "should return show Vistazo description" do
    get '/'
    last_response.body.must_include 'Vistazo is a simple, lightweight tool for small teams to see who is working on what, when.'
  end
  
end

describe "Vistazo week view" do
  
end