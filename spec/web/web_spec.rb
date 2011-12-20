require_relative '../spec_helper'

describe "Http authentication" do
  after do
    clean_db!
  end
  
  it "should work on all pages" do
    
    get "/"
    last_response.status.should == 401
    
    user = Factory(:user) # Create a user using factory, so that session doesn't need to be set up
    get user_team_path(user)
    last_response.status.should == 401
    
    get user_team_current_week_path(user)
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

describe "Teams:" do
  before do
    http_authorization!
    @session = init_omniauth_session
  end
  
  after do
    clean_db!
    @session = nil
  end
  
  describe "Week view" do
    it "should require login" do
      create_normal_user(@session)
      
      # Find added user
      team = User.first.team
      get_with_session_login! team_current_week_path(team), @session
      follow_redirect_with_session_login!(@session)
      
      last_response.body.should include("You must be logged in")
      last_response.body.should include("Start using Vistazo")
    end
  end
  
  pending "Can't have multiple people with the same email address"

  describe "User going into the wrong team" do
    it "should redirect them to their team week view and show an error message" do
      # Create super admin user and team
      login_super_admin_with_session!(@session)
      super_admin_team = user_from_session(@session).team
      logout_session!(@session)
      
      # Create normal user team
      login_normal_user_with_session!(@session)
      normal_user_team = user_from_session(@session).team
      
      # Try and log into super user team as normal user
      get_with_session_login! team_current_week_path(super_admin_team), @session
      follow_redirect_with_session_login!(@session)
      
      # Redirect to homepage
      last_request.path.should == "/"
      
      # Redirect to normal user team page
      follow_redirect_with_session_login!(@session)
      last_request.path.should == user_team_path(user_from_session(@session))
      
      # Redirect to normal user week view
      follow_redirect_with_session_login!(@session)
      last_request.path.should == user_team_current_week_path(user_from_session(@session))
      
      last_response.body.should include("You're not authorized to view this page")
      
    end
  end
  
end

describe "Projects:" do
  before do
    http_authorization!
    @session = init_omniauth_session
    
    create_normal_user(@session)
    login_normal_user_with_session!(@session)
      
    User.count.should == 1
    @team = User.first.team
      
    TeamMember.count.should == 1
    @team_member = TeamMember.first
  end
  
  after do
    clean_db!
    @session = nil
  end
  
  pending "Colour settings"
  
  describe "Create new project" do
    before do
      @valid_params = {
          "new_project_name" => "Business time",
          "team_id" => @team.id,
          "team_member_id" => @team_member.id,
          "date" => "2011-12-16",
          "new_project" => "true"
        }
    end
    
    it "should require login" do
      params = @valid_params
      post add_project_path(@team), @valid_params
      
      flash_message = last_request.session[:flash]
      flash_message[:warning].should include("You must be logged in.")
    end
    
    it "should show success message if passing valid parameters" do
      params = @valid_params
      post_params! add_project_path(@team), @valid_params, @session
      flash_message = last_request.session[:flash]
      flash_message[:success].should include("Successfully added '<em>Business time</em>' project for #{@team_member.name} on 2011-12-16.")
      Project.count.should == 1
      @team_member.reload.team_member_projects.count.should == 1
    end
    
    it "should show error message if new project name is not present or empty" do
      params = @valid_params.merge({ "new_project_name" => "" })
      post_params! add_project_path(@team), params, @session
      flash_message = last_request.session[:flash]
      flash_message[:warning].should include("Please specify a project name.")
      Project.count.should == 0
      @team_member.reload.team_member_projects.count.should == 0
      
      params = @valid_params.merge({ "new_project_name" => nil })
      post_params! add_project_path(@team), params, @session
      flash_message = last_request.session[:flash]
      flash_message[:warning].should include("Please specify a project name.")
      Project.count.should == 0
      @team_member.reload.team_member_projects.count.should == 0
      
      params = @valid_params.reject { |k,v| k == "new_project_name" }
      post_params! add_project_path(@team), params, @session
      flash_message = last_request.session[:flash]
      flash_message[:warning].should include("Please specify a project name.")
      Project.count.should == 0
      @team_member.reload.team_member_projects.count.should == 0
    end
  end
  
  describe "Add existing project" do
    before do
      params = {
          "new_project_name" => "Business time",
          "team_id" => @team.id,
          "team_member_id" => @team_member.id,
          "date" => "2011-12-16",
          "new_project" => "true"
        }
      post_params! add_project_path(@team), params, @session
      flash_message = last_request.session[:flash]
      flash_message[:success].should include("Successfully added '<em>Business time</em>' project for #{@team_member.name} on 2011-12-16.")
      Project.count.should == 1
      @project = Project.first
      @team_member.reload.team_member_projects.count.should == 1
      
      @date_to_add = "2012-01-15"
      @existing_project_params_to_add = {
        "project_id" => @project.id,
        "team_id" => @team.id,
        "team_member_id" => @team_member.id,
        "date" => @date_to_add
      }
    end
    
    it "should require login" do
      post add_project_path(@team), @existing_project_params_to_add
      
      flash_message = last_request.session[:flash]
      flash_message[:warning].should include("You must be logged in.")
    end
    
    it "should show success message if passing valid parameters" do
      post_params! add_project_path(@team), @existing_project_params_to_add, @session
      
      flash_message = last_request.session[:flash]
      flash_message[:success].should include("Successfully added '<em>#{@project.name}</em>' project for #{@team_member.name} on #{@date_to_add}.")
      Project.count.should == 1
      @team_member.reload.team_member_projects.count.should == 2   # Added another project
    end
  end
  
  describe "Update with json call" do
    before do
      @project_params = {
          "new_project_name" => "Business time",
          "team_id" => @team.id,
          "team_member_id" => @team_member.id,
          "date" => "2011-12-16",
          "new_project" => "true"
        }
      post_params! add_project_path(@team), @project_params, @session
      flash_message = last_request.session[:flash]
      flash_message[:success].should include("Successfully added '<em>Business time</em>' project for #{@team_member.name} on 2011-12-16.")  
      Project.count.should == 1
      @project = Project.first
      @team_member.reload.team_member_projects.count.should == 1
      @tm_project = @team_member.team_member_projects.first
      
      new_date = "2011-12-13"
      @valid_params = {
        "from_team_member_id" => @team_member.id,
        "to_team_member_id" => @team_member.id,
        "tm_project_id" => @tm_project.id,
        "to_date" => new_date
      }
    end
    
    it "should require login" do
      post update_project_path(@team, @tm_project), @valid_params
      
      flash_message = last_request.session[:flash]
      flash_message[:warning].should include("You must be logged in.")
    end
    
    it "should return 200 status with message if successfully moved to another date" do
      new_date = "2011-12-15"
      params = @valid_params.merge("to_date" => new_date)
      post_params! update_project_path(@team, @tm_project), params, @session
      
      # Shouldn't of created a new project
      Project.count.should == 1
      
      # Shouldn't of created a new team member project
      @team_member.reload.team_member_projects.count.should == 1
      
      last_response.status.should == 200
      last_response.body.should include("Successfully moved '<em>Business time</em>' project to #{@team_member.name} on #{new_date}.")
    end
    
    it "should return 200 status with message if successfully moved to another team member" do
      another_team_member = Factory(:team_member, :team => @team)
      params = @valid_params.merge(
        "to_team_member_id" => another_team_member.id,
        "to_date" => @project_params["date"]
      )
      post_params! update_project_path(@team, @tm_project), params, @session
      
      last_response.status.should == 200
      last_response.body.should include("Successfully moved '<em>Business time</em>' project to #{another_team_member.name} on #{@project_params["date"]}.")
    end

    it "should return 200 status with message if successfully moved to another person and another date" do
      another_team_member = Factory(:team_member, :team => @team)
      new_date = "2011-12-18"
      params = @valid_params.merge(
        "to_team_member_id" => another_team_member.id,
        "to_date" => new_date
      )
      post_params! update_project_path(@team, @tm_project), params, @session
      
      last_response.status.should == 200
      last_response.body.should include("Successfully moved '<em>Business time</em>' project to #{another_team_member.name} on #{new_date}.")
    end
    
    it "should return 400 error with message if moving to an invalid user" do
      error_team_member_id = "not_an_id"
      params = @valid_params.merge(
        "to_team_member_id" => error_team_member_id
      )
      post_params! update_project_path(@team, @tm_project), params, @session
      
      last_response.status.should == 400
      last_response.body.should include("Something went wrong with the input when updating team member project.")
    end
    
    it "should return 400 error with message if it is moved to a team member in another team" do
      another_team = Factory(:team)
      tm_in_another_team = Factory(:team_member, :team => another_team)
      params = @valid_params.merge(
        "to_team_member_id" => tm_in_another_team.id
      )
      post_params! update_project_path(@team, @tm_project), params, @session
      
      last_response.status.should == 400
      last_response.body.should include("Invalid team.")
    end
    
    pending "should return 400 error with message if it is moved from a team member in another team" do
      another_team = Factory(:team)
      tm_in_another_team = Factory(:team_member, :team => another_team)
      params = @valid_params.merge(
        "from_team_member_id" => tm_in_another_team.id
      )
      post_params! update_project_path(@team, @tm_project), params, @session
      
      last_response.status.should == 400
      last_response.body.should include("Invalid team.")
    end
    
    pending "should return 400 error with message if it is moved in an invalid team" do
      params = @valid_params
      post_params! update_project_with_team_id_path("invalid_team_id", @tm_project), params, @session
      
      last_response.status.should == 400
      last_response.body.should include("Invalid team.")
    end
    
    pending "should return 500 error with message if there is an internal error"
  end
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
    it "should create a new team with the user's name" do
      User.count.should == 0
      
      login_normal_user_with_session!(@session)
      
      # Should create new user
      User.count.should == 1
      
      # Should create new user team with user name
      team = User.first.team # Only have 1 user, so find first works
      team.name.should == "Vistazo Test's team"
      
      last_response.body.should include("Vistazo Test's team")
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
    it "should redirect them to their team week view" do
      create_normal_user(@session)
      
      login_normal_user_with_session!(@session)
      last_request.path.should == user_team_current_week_path(user_from_session(@session))
      last_response.body.should include("Vistazo Test's team")
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
    
    # Super admin team - default omniauth team is super admin
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