require_relative '../spec_helper'

# Define application for all spec files
def app
  Sinatra::Application
end

describe "Authentication" do
  it "should work on all pages" do
    all_pages = ['/', '/pebble_code_web_dev', '/pebble_code_web_dev/2011/week/48']
    
    all_pages.each do |page|
      get page
      last_response.status.should == 401
    end
  end
  
end

describe "Homepage" do
  before do
    http_authorization!
  end
  
  after do
    clean_db!
  end
  
  it "should return show welcome message" do
    get '/'
    last_response.body.should include('Welcome to the Vistazo prototype')
  end
  
end

describe "Admin:" do
  before do
    http_authorization!
  end
  
  describe "Reset database button" do
    it "should not be shown by default" do
      get '/'
      last_response.body.should_not include('Reset database')
    end
    
    it "should only show if ttt@pebblecode.com is logged in" do 
      pending "check that ttt@pebblecode.com is logged in"
    end
  end
end