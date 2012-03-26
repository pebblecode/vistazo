require_relative '../spec_helper'

describe "Http authentication" do
  after do
    clean_db!
  end
  
  it "should work on all pages" do
    
    get "/"
    last_response.status.should == 401
    
    user = Factory(:user, :teams => [Factory(:team)]) # Create a user using factory, so that session doesn't need to be set up
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
    last_response.body.should include("Start using vistazo")
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
  
  # New team: see new_team_spec.rb
  # Edit team: see team_name_spec.rb

  describe "Teams page" do
    it "should redirect to the home page and show an error if it is an invalid team" do
      create_normal_user(@session)
      
      # Find added user
      get_with_session_login! team_id_path("invalid_id"), @session
      follow_redirect_with_session_login!(@session)
      
      last_request.path.should == "/"
      last_response.body.should include("Invalid team.")
    end
  end
  
  describe "Week view" do
    it "should require login" do
      create_normal_user(@session)
      
      # Find added user
      team = User.first.teams.first
      get_with_session_login! team_current_week_path(team), @session
      follow_redirect_with_session_login!(@session)
      
      last_response.body.should include("You must be logged in")
      last_response.body.should include("Start using vistazo")
    end
  end

  describe "User going into the wrong team" do
    it "should redirect them to their team week view and show an error message" do
      # Create super admin user and team
      login_super_admin_with_session!(@session)
      super_admin_team = user_from_session(@session).teams.first
      logout_session!(@session)
      
      # Create normal user team
      login_normal_user_with_session!(@session)
      normal_user_team = user_from_session(@session).teams.first
      
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

describe "Users:" do
  before do
    http_authorization!
    @session = init_omniauth_session

    create_normal_user(@session)
    @user = User.first
    @team = @user.teams.first

    login_normal_user_with_session!(@session)
  end
  
  after do
    clean_db!
    @session = nil
  end

  describe "create user" do
    before do
      @valid_params = {
        :name => "Johnny Cash",
        :email => "johnny@folsom.com",
        :is_visible => true
      }
    end

    it "should work" do
      post_params! team_add_user(@team), @valid_params, @session
      @team.reload
      @new_user = User.find_by_email(@valid_params[:email])
      
      @new_user.name.should == @valid_params[:name]
      @new_user.email.should == @valid_params[:email]

      @team.user_timetable(@new_user).is_visible.should == true
    end

    describe "should work for users where users are not visible" do
      it "when :is_visible is false" do
        @valid_params[:is_visible] = false

        post_params! team_add_user(@team), @valid_params, @session
        @team.reload
        @new_user = User.find_by_email(@valid_params[:email])

        @team.user_timetable(@new_user).is_visible.should == false
      end

      it "when :is_visible is not present in params" do
        @valid_params.delete(:is_visible)

        post_params! team_add_user(@team), @valid_params, @session
        @team.reload
        @new_user = User.find_by_email(@valid_params[:email])

        @team.user_timetable(@new_user).is_visible.should == false
      end
    end
  end

  describe "update user" do
    it "should update user name" do
      params = {
        :name => "New face",
        :is_visible => true
      }
      post_params! team_update_user(@team, @user), params, @session
      @user.reload

      @user.name.should == "New face"
    end

    describe "is_visible status" do
      before do
        @team.user_timetable(@user).is_visible.should == true
      end

      it "should not update if name is not sent as well" do
        params = {
          :is_visible => false
        }
        post_params! team_update_user(@team, @user), params, @session
        @team.reload

        # Should not change
        @team.user_timetable(@user).is_visible.should == true
      end

      it "should update for true" do
        params = {
          :name => "Something",
          :is_visible => true
        }
        post_params! team_update_user(@team, @user), params, @session
        @team.reload

        @team.user_timetable(@user).is_visible.should == true
      end

      it "should update for false (but param of false is not actually passed in html in practice)" do
        params = {
          :name => "Something",
          :is_visible => false
        }
        post_params! team_update_user(@team, @user), params, @session
        @team.reload

        @team.user_timetable(@user).is_visible.should == false
      end

      it "should update to false if is_visible is not passed in params" do
        params = {
          :name => "Something"
        }
        post_params! team_update_user(@team, @user), params, @session
        @team.reload

        @team.user_timetable(@user).is_visible.should == false
      end
    end
  end

  describe "delete user" do
    before do
      new_user_params = { 
        :name => "Karen O", 
        :email => "karen.o@gmail.com"
      }
      post_params! team_add_user(@team), new_user_params, @session
      @team.reload

      @new_user = User.find_by_email(new_user_params[:email])
    end

    it "should delete user" do
      User.find(@new_user.id).present?.should == true
      post_params! team_delete_user(@team, @new_user), nil, @session

      User.find(@new_user.id).present?.should == false
    end

    it "should delete user timetable" do
      @team.has_user_timetable?(@new_user).should == true
      post_params! team_delete_user(@team, @new_user), nil, @session
      @team.reload

      @team.has_user_timetable?(@new_user).should == false
    end
  end
end

describe "Timetable items:" do
  before do
    http_authorization!
    @session = init_omniauth_session

    create_normal_user(@session)
    @user = User.first
    @team = @user.teams.first

    @project = Project.create(:name => "Take over world", :team => @team)
    @date = Time.now
    @timetable_item = @team.add_timetable_item(@user, @project, @date)

    login_normal_user_with_session!(@session)
  end
  
  after do
    clean_db!
    @session = nil
  end
  
  describe "Delete timetable items" do
    it "should delete" do
      post_params! delete_timetable_item_path(@team, @user, @timetable_item), nil, @session
    end
  end

end

describe "Delete project:" do
  before do
    http_authorization!
    @session = init_omniauth_session
    
    create_normal_user(@session)
    @team = User.first.teams.first
  end
  
  it "should require login" do
    @project = Project.create(:name => "New project", :team_id => @team.id)
    post_params! delete_project_path(@team, @project), nil, @session
    
    flash_message = last_request.session[:flash]
    flash_message[:warning].should include("You must be logged in.")
  end
  
  describe "After login:" do
    before do
      login_normal_user_with_session!(@session)
    end
    
    describe "from a different team" do
      it "should give you an error message" do
        @user = User.first
        
        @project = Project.create(:name => "Business time", :team_id => @team.id)
        @other_team = Team.create(:name => "Monday-itis")
        @other_team.add_user(@user)
        @other_team.activate_user(@user)
        
        post_params! delete_project_path(@other_team, @project), nil, @session
        
        flash_message = last_request.session[:flash]
        flash_message[:warning].should include("Invalid team.")
      end
    end
    
    describe "with an invalid project" do
      it "should give you an error message" do
        post_params! delete_project_path_with_project_id(@team, "1234"), nil, @session
        
        flash_message = last_request.session[:flash]
        flash_message[:warning].should include("Invalid project.")
      end
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
    @team = User.first.teams.first
      
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
      post add_project_path(@team, @team_member), @valid_params
      
      flash_message = last_request.session[:flash]
      flash_message[:warning].should include("You must be logged in.")
    end
    
    it "should show success message if passing valid parameters" do
      params = @valid_params
      pending("Check in js")
      post_params! add_project_path(@team, @team_member), @valid_params, @session
      flash_message = last_request.session[:flash]
      flash_message[:success].should include("Successfully added '<em>Business time</em>' project for #{@team_member.name} on 2011-12-16.")
      Project.count.should == 1
      @team_member.reload.timetable_items.count.should == 1
    end
    
    it "should show error message if new project name is not present or empty" do
      params = @valid_params.merge({ "new_project_name" => "" })
      pending("Check in js")
      post_params! add_project_path(@team, @team_member), params, @session
      flash_message = last_request.session[:flash]
      flash_message[:warning].should include("Please specify a project name.")
      Project.count.should == 0
      @team_member.reload.timetable_items.count.should == 0
      
      params = @valid_params.merge({ "new_project_name" => nil })
      post_params! add_project_path(@team, @team_member), params, @session
      flash_message = last_request.session[:flash]
      flash_message[:warning].should include("Please specify a project name.")
      Project.count.should == 0
      @team_member.reload.timetable_items.count.should == 0
      
      params = @valid_params.reject { |k,v| k == "new_project_name" }
      post_params! add_project_path(@team, @team_member), params, @session
      flash_message = last_request.session[:flash]
      flash_message[:warning].should include("Please specify a project name.")
      Project.count.should == 0
      @team_member.reload.timetable_items.count.should == 0
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
      pending("Check in js")
      post_params! add_project_path(@team, @team_member), params, @session
      flash_message = last_request.session[:flash]
      flash_message[:success].should include("Successfully added '<em>Business time</em>' project for #{@team_member.name} on 2011-12-16.")
      Project.count.should == 1
      @project = Project.first
      @team_member.reload.timetable_items.count.should == 1
      
      @date_to_add = "2012-01-15"
      @existing_project_params_to_add = {
        "project_id" => @project.id,
        "team_id" => @team.id,
        "team_member_id" => @team_member.id,
        "date" => @date_to_add
      }
    end
    
    it "should require login" do
      pending("Check in js")
      post add_project_path(@team, @team_member), @existing_project_params_to_add
      
      flash_message = last_request.session[:flash]
      flash_message[:warning].should include("You must be logged in.")
    end
    
    it "should show success message if passing valid parameters" do
      pending("Check in js")
      post_params! add_project_path(@team, @team_member), @existing_project_params_to_add, @session
      
      flash_message = last_request.session[:flash]
      flash_message[:success].should include("Successfully added '<em>#{@project.name}</em>' project for #{@team_member.name} on #{@date_to_add}.")
      Project.count.should == 1
      @team_member.reload.timetable_items.count.should == 2   # Added another project
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
      pending("Check in js")
      post_params! add_project_path(@team, @team_member), @project_params, @session
      flash_message = last_request.session[:flash]
      flash_message[:success].should include("Successfully added '<em>Business time</em>' project for #{@team_member.name} on 2011-12-16.")  
      Project.count.should == 1
      @project = Project.first
      @team_member.reload.timetable_items.count.should == 1
      @tm_project = @team_member.timetable_items.first
      
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
      @team_member.reload.timetable_items.count.should == 1
      
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
      team = User.first.teams.first # Only have 1 user, so find first works
      team.name.should == DEFAULT_TEAM_NAME
      
      last_response.body.should include(DEFAULT_TEAM_NAME)
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
      last_response.body.should include(DEFAULT_TEAM_NAME)
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
      last_response.body.should include("is-super-admin")
    end
  end
  
  describe "Logged in normal user" do
    it "should not have 'is-super-admin' in the body class" do
      login_normal_user_with_session!(@session)
      last_response.body.should_not include("is-super-admin")
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