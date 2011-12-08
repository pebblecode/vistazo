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
    @session = SessionData.new(rack_test_session.instance_variable_get(:@rack_mock_session).cookie_jar)
  end
  
  after do
    clean_db!
  end
  
  describe "Logging in as a new user" do
    it "should create a new account with the user's name" do
      User.count.should == 0
      
      get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2] }
      last_request.session[:flash][:success].should include("Welcome to Vistazo!")
      
      @session.merge!(last_request.session)
      # Logged in user should have the same uid as login credentials
      @session['uid'].should == OmniAuth.config.mock_auth[:google_oauth2]['uid']
      
      # Should create new user
      User.count.should == 1
      
      account = User.first.account
      account.should_not == nil
      account.name.should == "Tu Tak Tran's schedule"
      
      # Should redirect to homepage
      follow_redirect_with_session_login!(@session)
      last_request.path.should == "/"
      
      # Should redirect to account page
      follow_redirect_with_session_login!(@session)
      last_request.path.should == "/#{account.id}"
      
      # Should redirect to current week
      follow_redirect_with_session_login!(@session)
      last_request.path.should == "/#{account.id}/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
      last_response.body.should include("Tu Tak Tran's schedule")
      last_response.body.should include("Welcome to Vistazo")
    end
  end
  
  describe "Logging out" do
    it "should return to homepage" do
      login!(@session)
      
      get_with_session_login '/logout', @session
      last_request.session['uid'].should == nil
      last_request.session[:flash][:success] == "Logged out successfully"
      
      follow_redirect!
      last_request.path.should == "/"
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