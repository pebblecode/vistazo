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
  
  it "should return show welcome message" do
    get '/'
    last_response.body.should include('Welcome to the Vistazo prototype')
  end
  
end

describe "Accounts:" do
  pending "Can't have multiple people with the same email address"

  pending "User going into the wrong account"
end

describe "Team members:" do
  pending "Add team members"
end

describe "Projects:" do
  pending "Colour settings"
end

describe "Users:" do
  pending "Add users (email etc.)"
end

describe "Authentication:" do
  before do
    http_authorization!
    @session = init_omniauth_session
  end
  
  after do
    clean_db!
    @session = nil
  end
  
  describe "Logging in as a new user" do
    it "should create a new account with the user's name" do
      User.count.should == 0
      
      login!(:normal_user, @session)
      
      # Should create new user
      User.count.should == 1
      
      # Should create new user account with user name
      account = User.first.account # Only have 1 user, so find first works
      account.name.should == "Vistazo Test's schedule"
      
      last_response.body.should include("Vistazo Test's schedule")
      last_response.body.should include("Welcome to Vistazo")
    end
  end
  
  pending "Login rejected workflow"
  
  pending "Logging in as an existing user"
  
  pending "Protect all pages with login redirect"
  
  describe "Logging out" do
    it "should return to homepage" do
      login!(:normal_user, @session)
      
      get_with_session_login '/logout', @session
      last_request.session['uid'].should == nil
      last_request.session[:flash][:success] == "Logged out successfully"
      
      follow_redirect!
      last_request.path.should == "/"
    end
  end
end

describe "Admin:" do
  before do
    http_authorization!
    
    # Super admin account - default omniauth account is super admin
    @session = init_omniauth_session
  end
  
  after do
    clean_db!
    @session = nil
  end
  
  describe "Logged in super admin" do
    it "should have 'is-super-admin' in the body class" do
      login!(:super_admin, @session)
      last_response.body.should include("<body class='is-super-admin'>")
    end
  end
  
  describe "Logged in normal user" do
    it "should not have 'is-super-admin' in the body class" do
      login!(:normal_user, @session)
      last_response.body.should_not include("<body class='is-super-admin'>")
    end
  end
  
  describe "Reset database button" do
    it "should not be shown by default" do
      get '/'
      last_response.body.should_not include('Reset database')
    end
    
    it "should only show if a user with the email ttt@pebblecode.com is logged in" do       
      User.count.should == 0
      login!(:super_admin, @session)
      last_response.body.should include('Reset database')
      User.count.should == 1
      
      # Change email
      user = User.first
      user.email.should == "ttt@pebblecode.com"
      user.email = "fake.ttt@pebblecode.com"
      user.save
      user.should be_valid
      
      # Shouldn't see reset database anymore
      user.email.should_not == "ttt@pebblecode.com"
      login!(:super_admin, @session)
      last_response.body.should_not include('Reset database')
      
      get '/logout'
      
      # Shouldn't see reset database as a normal user
      login!(:normal_user, @session)
      last_response.body.should_not include('Reset database')
      
      # But if the email changes, then you will see it
      normal_user = User.find_by_email("vistazo.test@gmail.com")
      normal_user.email = "ttt@pebblecode.com" # Can have multiple people with the same email! Yikes!
      normal_user.save
      normal_user.should be_valid
      
      login!(:normal_user, @session)
      last_response.body.should include('Reset database')
    end
  end
end