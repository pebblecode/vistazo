require_relative '../spec_helper'

describe "Http authentication" do
  after do
    clean_db!
  end
  
  it "should work on all pages" do
    
    get "/"
    last_response.status.should == 401
    
    user = Factory(:user) # Create a user using factory, so that session doesn't need to be set up
    get user_account_path(user)
    last_response.status.should == 401
    
    get user_account_current_week_path(user)
    last_response.status.should == 401
  end
  
end

describe "Homepage" do
  before do
    http_authorization!
  end
  
  it "should have 'Start using Vistazo'" do
    get '/'
    last_response.body.should include("Start using Vistazo")
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
      create_normal_user(@session)
      
      # Find added user
      account = User.first.account
      get_with_session_login! account_current_week_path(account), @session
      follow_redirect_with_session_login!(@session)
      
      last_response.body.should include("You must be logged in")
      last_response.body.should include("Start using Vistazo")
    end
  end
  
  pending "Can't have multiple people with the same email address"

  describe "User going into the wrong account" do
    it "should redirect them to their account week view and show an error message" do
      # Create super admin user and account
      login_super_admin_with_session!(@session)
      super_admin_account = user_from_session(@session).account
      logout_session!(@session)
      
      # Create normal user account
      login_normal_user_with_session!(@session)
      normal_user_account = user_from_session(@session).account
      
      # Try and log into super user account as normal user
      get_with_session_login! account_current_week_path(super_admin_account), @session
      follow_redirect_with_session_login!(@session)
      
      # Redirect to homepage
      last_request.path.should == "/"
      
      # Redirect to normal user account page
      follow_redirect_with_session_login!(@session)
      last_request.path.should == user_account_path(user_from_session(@session))
      
      # Redirect to normal user week view
      follow_redirect_with_session_login!(@session)
      last_request.path.should == user_account_current_week_path(user_from_session(@session))
      
      last_response.body.should include("You're not authorized to view this page")
      
    end
  end
  
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
  
  describe "Logging in with wrong credentials:" do
    describe "empty omniauth.auth hash" do
      it "should redirect to homepage with error message" do
        get_with_session_login! google_oauth2_callback_path, @session
        follow_redirect_with_session_login!(@session)

        last_request.path.should == "/"
        last_response.body.should include("Invalid login: No details.")
      end
    end
    
    describe "nil" do
      describe "uid" do
        it "should redirect to homepage with error message" do
          empty_oa_credentials = OmniAuth.config.mock_auth[:default].merge({
            "uid" => '',
            "info" => {
              "email" => '',
              "name" => ''
            }
          })
          get google_oauth2_callback_path, nil, { "omniauth.auth" => empty_oa_credentials }
          @session.merge!(last_request.session)
          follow_redirect_with_session_login!(@session)
          
          last_request.path.should == "/"
          last_response.body.should include("Invalid login: No user id.")
        end
      end
      
      describe "email" do
        it "should redirect to homepage with error message" do
          no_email_oa_credentials = OmniAuth.config.mock_auth[:normal_user].merge({
            "info" => {
              "email" => '',
              "name" => ''
            }
          })
          get google_oauth2_callback_path, nil, { "omniauth.auth" => no_email_oa_credentials }
          @session.merge!(last_request.session)
          follow_redirect_with_session_login!(@session)
          
          last_request.path.should == "/"
          last_response.body.should include("Invalid login: No email.")
        end
      end
    end
  end
  
  describe "User save failure" do
    # Not sure how to test this
    pending "Should show 'Could not retrieve user' message"
  end
  
  describe "Logging in as an existing user" do
    it "should redirect them to their account week view" do
      create_normal_user(@session)
      
      login_normal_user_with_session!(@session)
      last_request.path.should == user_account_current_week_path(user_from_session(@session))
      last_response.body.should include("Vistazo Test's schedule")
    end
  end
  
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

describe "Error handling:" do
  describe "Error page" do
    it "should raise RuntimeError" do
      lambda { get "/error" }.should raise_error(RuntimeError, "Sample error")
    end
    it "Error page should be tested in integration tests" do
      true.should == true
    end
  end
end