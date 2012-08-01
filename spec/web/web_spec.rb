require_relative '../spec_helper'

describe "Homepage" do
  before do
    http_authorization!
  end

  it "should have 'Start using Vistazo'" do
    get '/'
    last_response.body.should include("Start using vistazo")
  end
end

describe "Week view" do
  before do
    http_authorization!
    @session = init_omniauth_session
  end

  after do
    clean_db!
    @session = nil
  end

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

    it "should fail for invalid emails" do
      @invalid_params = @valid_params.merge({
        :email => "johnny_no_good"
      })
      post_params! team_add_user(@team), @invalid_params, @session
      @team.reload

      last_response.status.should == 400
      response_hash = ActiveSupport::JSON.decode(last_response.body)
      response_hash["message"].should == "Invalid user"

      @new_user = User.find_by_email(@valid_params[:email])
      @new_user.should == nil

      @team.has_user_timetable?(@new_user).should == false
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

    it "should delete user if the user has no more teams" do
      User.find(@new_user.id).present?.should == true
      post_params! team_delete_user(@team, @new_user), nil, @session

      User.find(@new_user.id).present?.should == false
    end

    it "should not delete user if the user is in another team" do
      another_team = Factory(:team)
      another_team.add_user(@new_user)
      another_team.reload
      @new_user.reload

      post_params! team_delete_user(@team, @new_user), nil, @session
      User.find(@new_user.id).present?.should == true
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

    login_normal_user_with_session!(@session)
  end

  after do
    clean_db!
    @session = nil
  end

  describe "Add timetable item" do
    # Tested in add existing and new projects
  end

  describe "Update timetable item" do
    before do
      @date = Time.new(2012, 3, 26)
      @another_date = (@date + 1.day)
      @user_timetable = UserTimetable.find_by_user_id(@user.id)
      @timetable_item = Factory(:timetable_item, :user_timetable => @user_timetable, :project => @project, :date => @date)

      @another_user = Factory(:user)
      @team.add_user(@another_user)

      @from_user = @user
      @from_date = @date
      @team.reload
    end

    it "should require login" do
      post update_timetable_item_path(@team, @timetable_item), nil

      flash_message = last_request.session[:flash]
      flash_message[:warning].should include("You must be logged in.")
    end

    describe "to different date and same user" do
      before do
        @to_user = @user
        @to_date = @another_date
        @params = {
          "from_user_id" => @from_user.id,
          "to_user_id" => @to_user.id,
          "to_date" => @to_date
        }

        post_params! update_timetable_item_path(@team, @timetable_item), @params, @session
        @team.reload
      end

      it "should not create any new projects" do
        Project.count.should == 1
      end

      it "should not create any new timetable items" do
        TimetableItem.where({:user_id => @from_user.id}).count.should == 1
      end

      it "should return 200 status" do
        last_response.status.should == 200
      end

      it "should return a success message" do
        last_response.body.should include("Successfully moved '#{@project.name}' project to #{@to_user.name} on #{@to_date.strftime("%F")}.")
      end
    end

    describe "to same date and different user" do
      before do
        @to_user = @another_user
        @to_date = @date
        @params = {
          "from_user_id" => @from_user.id,
          "to_user_id" => @to_user.id,
          "to_date" => @from_date
        }

        post_params! update_timetable_item_path(@team, @timetable_item), @params, @session
        @team.reload
      end

      it "should return 200 status" do
        last_response.status.should == 200
      end

      it "should return a success message" do
        last_response.body.should include("Successfully moved '#{@project.name}' project to #{@to_user.name} on #{@to_date.strftime("%F")}.")
      end
    end

    describe "to different date and different user" do
      before do
        @to_user = @another_user
        @to_date = @another_date
        @params = {
          "from_user_id" => @from_user.id,
          "to_user_id" => @to_user.id,
          "to_date" => @to_date
        }

        post_params! update_timetable_item_path(@team, @timetable_item), @params, @session
        @team.reload
      end

      it "should return 200 status" do
        last_response.status.should == 200
      end

      it "should return a success message" do
        last_response.body.should include("Successfully moved '#{@project.name}' project to #{@to_user.name} on #{@to_date.strftime("%F")}.")
      end
    end

    describe "to invalid user" do
      before do
        @to_date = @date
        @params = {
          "from_user_id" => @from_user.id,
          "to_user_id" => "not_a_valid_user",
          "to_date" => @to_date
        }

        post_params! update_timetable_item_path(@team, @timetable_item), @params, @session
        @team.reload
      end

      it "should return 400 status" do
        last_response.status.should == 400
      end

      it "should return error message" do
        last_response.body.should include("Something went wrong with the input when updating timetable item.")
      end
    end

    describe "to a user in another team" do
      before do
        @another_team = Factory(:team)
        @another_team_user = Factory(:user)
        @another_team.add_user(@another_team_user)

        @to_user = @another_team_user
        @to_date = @another_date

        @params = {
          "from_user_id" => @from_user.id,
          "to_user_id" => @to_user.id,
          "to_date" => @to_date
        }

        post_params! update_timetable_item_path(@team, @timetable_item), @params, @session
        @team.reload
      end

      it "should return 400 status" do
        last_response.status.should == 400
      end

      it "should return error message" do
        last_response.body.should include("Invalid team.")
      end
    end
  end

  describe "Delete timetable items" do
    before do
      @date = Time.new(2012, 3, 26)
      @another_date = (@date + 1.day)
      @timetable_item = Factory(:timetable_item, :user => @user, :project => @project, :date => @date, :team => @team)
    end

    it "should delete" do
      post_params! delete_timetable_item_path(@team, @user, @timetable_item), nil, @session
      @team.reload

      TimetableItem.count.should == 0
    end
  end
end

describe "Delete project:" do
  before do
    http_authorization!
    @session = init_omniauth_session

    create_normal_user(@session)
    @user = User.first
    @team = @user.teams.first
    @user_timetable = Factory(:user_timetable, :team => @team, :user => @user)
  end

  after do
    clean_db!
    @session = nil
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

    describe "with a valid project" do
      before do
        @project = Project.create(:name => "Business time", :team => @team)
      end

      it "should delete project from all projects" do
        post_params! delete_project_path(@team, @project), nil, @session

        Project.find(@project.id).nil?.should == true
      end

      describe "delete from all team timetables" do
        before do
          @date = Time.now
        end

        it "should delete for 1 timetable item" do

          Factory(:timetable_item, :project => @project, :date => @date, :user_timetable => @user_timetable)
          TimetableItem.find_by_user_id(@user.id).nil? == false

          post_params! delete_project_path(@team, @project), nil, @session

          TimetableItem.find_by_user_id(@user.id).nil? == true
        end

        it "should delete for multiple timetable items with same project but different dates" do
          Factory(:timetable_item, :project => @project, :user_timetable => @user_timetable, :date => @date)
          Factory(:timetable_item, :project => @project, :user_timetable => @user_timetable, :date => @date + 1.day)
          Factory(:timetable_item, :project => @project, :user_timetable => @user_timetable, :date => @date + 5.day)

          TimetableItem.count.should == 3

          post_params! delete_project_path(@team, @project), nil, @session

          TimetableItem.count.should == 0
        end

        it "should delete for different users" do
          @other_user = Factory(:user)
          @team.add_user(@other_user)
          @other_user_timetable = Factory(:user_timetable, :user => @other_user, :team => @team)

          Factory(:timetable_item, :project => @project, :date => @date, :user_timetable => @user_timetable)
          Factory(:timetable_item, :project => @project, :date => @date, :user_timetable => @other_user_timetable)

          TimetableItem.count.should == 2
          TimetableItem.where({:user_id => @other_user.id}).count.should == 1

          post_params! delete_project_path(@team, @project), nil, @session

          TimetableItem.count.should == 0
        end
      end

      it "should show successful flash message" do
        @project = Project.create(:name => "Business time", :team => @team)
        post_params! delete_project_path(@team, @project), nil, @session

        flash_message = last_request.session[:flash]
        flash_message[:success].should include("Successfully deleted project 'Business time'.")
      end
    end

    describe "from a different team" do
      it "should give you an error message" do
        @user = User.first

        @project = Project.create(:name => "Business time", :team_id => @team.id)
        @other_team = Team.create(:name => "Monday-itis")
        @other_team.add_user(@user)

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
    @user = User.first
    @team = @user.teams.first
  end

  after do
    clean_db!
    @session = nil
  end

  pending "Colour settings"

  describe "Create new project" do
    before do
      @params = {
        "project_name" => "Business time",
        "date" => "2011-12-16"
      }
    end

    it "should require login" do
      post add_timetable_item_path(@team, @user), @valid_params

      flash_message = last_request.session[:flash]
      flash_message[:warning].should include("You must be logged in.")
    end

    it "should show success message if passing valid parameters" do
      post_params! add_timetable_item_path(@team, @user), @params.to_json, @session
      Project.count.should == 1

      last_response.body.should include("Successfully added 'Business time' project for #{@user.name} on 2011-12-16.")

      @team.reload
      TimetableItem.count.should == 1
    end

    it "should return error message if project name is empty string or nil" do
      invalid_params = @params.merge({
        "project_name" => ""
      })
      post_params! add_timetable_item_path(@team, @user), invalid_params.to_json, @session

      last_response.body.should include("Please specify a project name.")

      Project.count.should == 0
      @team.reload
      TimetableItem.count.should == 0

      invalid_params = @params.merge({
        "project_name" => nil
      })
      post_params! add_timetable_item_path(@team, @user), invalid_params.to_json, @session

      last_response.body.should include("Please specify a project name.")

      Project.count.should == 0
      @team.reload
      TimetableItem.count.should == 0
    end
  end

  describe "Add existing project" do
    before do
      @project = Factory(:project, :team => @team)
      @date_to_add = "2012-02-01"
      @params = {
        "project_id" => @project.id,
        "date" => @date_to_add
      }
    end

    it "should require login" do
      post add_timetable_item_path(@team, @user), @params

      flash_message = last_request.session[:flash]
      flash_message[:warning].should include("You must be logged in.")
    end

    it "should show success message if passing valid parameters" do
      post_params! add_timetable_item_path(@team, @user), @params.to_json, @session

      last_response.body.should include("Successfully added '#{@project.name}' project for #{@user.name} on #{@date_to_add}.")
      Project.count.should == 1

      @team.reload
      TimetableItem.count.should == 1
    end
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

      last_response.body.should include(SANITIZED_DEFAULT_TEAM_NAME)
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
      last_response.body.should include(SANITIZED_DEFAULT_TEAM_NAME)
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