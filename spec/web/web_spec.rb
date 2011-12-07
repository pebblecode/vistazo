require_relative '../spec_helper'

# Define application for all spec files
def app
  Sinatra::Application
end

describe "Http authentication" do
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

describe "Authentication:" do
  before do
    http_authorization!
    
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(:google_oauth2, {
      :uid => '111965288093828509275',
      :info => {
        :email => "ttt@pebblecode.com",
        :name => 'Tu Tak Tran'
      }
    })
  end
  
  after do
    clean_db!
  end
  
  describe "Logging in as a new user" do
    it "should create a new account with the user's name" do
      get '/auth/google_oauth2/callback', nil, {"omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2]}
      follow_redirect!
      # debugger
      last_response.body.should include("Tu Tak Tran's schedule")
    end
  end
  
  describe "Logging out" do
    pending "should return to homepage" do
      get '/auth/google_oauth2/'
      
      get '/logout'
      last_response.status.should == 302 # Follow redirect
      follow_redirect!
      last_request.path.should == "/"
      last_response.body.should include("Logged out successfully")
    end
  end
end

# OmniAuth.config.mock_auth[:google_oauth2] = {
#     'provider' => 'google',
#     'uid' => '111965288093828509275'
#     'email' => "ttt@pebblecode.com"
#     'name' => 'Tu Tak Tran'
#   }

# describe "Admin:" do
#   before do
#     http_authorization!
#     
#     # Super admin account
#     OmniAuth.config.add_mock(:google_oauth2, {
#       :uid => '111965288093828509275',
#       :email => "ttt@pebblecode.com",
#       :name => 'Tu Tak Tran'})
#   end
#   
#   describe "Logged in super admin" do
#     it "should have 'is-super-admin' in the body class" do
#       get '/auth/google_oauth2'
#       last_response.body.should include("<body class='is-super-admin'>")
#     end
#   end
#   
#   describe "Reset database button" do
#     it "should not be shown by default" do
#       get '/'
#       last_response.body.should_not include('Reset database')
#     end
#     
#     it "should only show if ttt@pebblecode.com is logged in" do 
#       pending "check that ttt@pebblecode.com is logged in"
#     end
#   end
# end