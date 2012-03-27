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
      debugger
      users = backbone_collection_on_page(:users, page)

      users.last["name"].should == "Ha! <script type='text/javascript'>alert('hello!');</script>"
    end
  end
  
  pending "name can be edited"
  
  pending "name edited as empty string should show error"
  
  pending "can be deleted"

  pending "update user"
end
