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
  
  it "should have sign in link" do
    get '/'
    last_response.body.should include("Sign in")
  end
end

describe "Accounts:" do
  before do
    http_authorization!
    @session = init_omniauth_session
  end
  
  after do
    clean_db!
    @session = nil
  end
  
  describe "Week view" do
    it "should be require login" do
      # Create user and account
      login_normal_user_with_session!(@session)
      logout_session!(@session)
      
      account = User.first.account
      get_with_session_login! "/#{account.id}/#{Time.now.year}/week/#{Time.now.strftime("%U")}", @session
      follow_redirect_with_session_login!(@session)
      
      last_response.body.should include("You must be logged in")
      last_response.body.should include("Sign in")
    end
  end
  
  pending "Can't have multiple people with the same email address"

  describe "User going into the wrong account" do
    it "should redirect them to their account week view and show an error message" do
      # Create super admin user and account
      login_super_admin_with_session!(@session)
      super_admin = user_from_session(@session)
      super_admin_account = super_admin.account
      logout_session!(@session)
      
      # Create normal user account
      login_normal_user_with_session!(@session)
      normal_user = user_from_session(@session)
      normal_user_account = normal_user.account
      
      # Try and log into super user account as normal user
      get_with_session_login! "/#{super_admin_account.id}/#{Time.now.year}/week/#{Time.now.strftime("%U")}", @session
      follow_redirect_with_session_login!(@session)
      
      # Redirect to homepage
      last_request.path.should == "/"
      
      # Redirect to normal user account page
      follow_redirect_with_session_login!(@session)
      last_request.path.should == "/#{normal_user_account.id}"
      
      # Redirect to normal user week view
      follow_redirect_with_session_login!(@session)
      last_request.path.should == "/#{normal_user_account.id}/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
      
      last_response.body.should include("You're not authorized to view this page")
      
    end
  end
  
end

describe "Team members:" do
  pending "Adding team members should require log in"
  pending "Add team members"
end

describe "Projects:" do
  pending "Colour settings"
  pending "Move projects"
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

  describe "Mandatory log in" do
    it "should be tested in feature tests" do
      true.should == true
    end
  end
  
  describe "Logging in as a new user" do
    it "should create a new account with the user's name" do
      User.count.should == 0
      
      login_normal_user_with_session!(@session)
      
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
      login_normal_user_with_session!(@session)
      logout_session!(@session)
      
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
      login_super_admin_with_session!(@session)
      last_response.body.should include("<body class='is-super-admin'>")
    end
  end
  
  describe "Logged in normal user" do
    it "should not have 'is-super-admin' in the body class" do
      login_normal_user_with_session!(@session)
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
      login_super_admin_with_session!(@session)
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
      login_super_admin_with_session!(@session)
      last_response.body.should_not include('Reset database')
      
      logout_session!(@session)
      
      # Shouldn't see reset database as a normal user
      login_normal_user_with_session!(@session)
      last_response.body.should_not include('Reset database')
      
      # But if the email changes, then you will see it
      normal_user = User.find_by_email("vistazo.test@gmail.com")
      normal_user.email = "ttt@pebblecode.com" # Can have multiple people with the same email! Yikes!
      normal_user.save
      normal_user.should be_valid
      
      login_normal_user_with_session!(@session)
      last_response.body.should include('Reset database')
    end
  end
end