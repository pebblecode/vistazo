require_relative '../spec_helper'

feature "User" do
  background do
    http_authorization_capybara!

    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    @team = Team.first
    @user = User.first
  end

  after do
    clean_db!
  end

  describe "login" do
    before do
      visit "/"
      click_link "start-btn"
    end

    scenario "should store last login for users first login" do
      # Give it about 1 minute for the test to run
      @user.last_logged_in.should be_between(Time.now - 1.minute, Time.now)
    end

    scenario "should store last login for users subsequent logins" do
      visit "/"
      @user.last_logged_in.should be_between(Time.now - 1.minute, Time.now)
    end
  end

  describe "first fresh login" do
    before do
      visit "/"
      click_link "start-btn"
    end

    scenario "has first-signon body class on first login" do
      page.body.should include("first-signon")

      visit "/"
      page.body.should_not include("first-signon")
    end

    scenario "is in team" do
      user_timetables = backbone_collection_on_page(:user_timetables, page)
      user_timetables.length.should == 1
      user_timetables.first["user_id"].should == @user.id.to_s
    end
  end

  describe "add" do

    scenario "malicious script tag should be sanitized" do
      @user = Factory(:user, :name => "Ha! <script type='text/javascript'>alert('hello!');</script>")
      @team.add_user(@user)

      visit "/"
      click_link "start-btn"
      visit "/"

      users = backbone_collection_on_page(:users, page)
      user = users.select { |u| u["email"] == @user.email }.first

      user["name"].should == Rack::Utils.escape_html("Ha! <script type='text/javascript'>alert('hello!');</script>")
    end
  end

  pending "name can be edited"

  pending "name edited as empty string should show error"

  pending "can be deleted"

  pending "update user"
end
