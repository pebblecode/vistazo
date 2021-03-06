require_relative '../spec_helper'

feature "Month view" do
  background do
    http_authorization_capybara!

    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    @user = User.first
    @team = Team.first
  end

  after do
    clean_db!
    @session = nil
  end

  scenario "should show error message if there is an invalid team id" do
    visit "/"
    click_link "start-btn"

    visit team_id_month_path("invalid_id", 2012, 4)
    page.should have_content("You're not authorized to view this page")
  end

  describe "after logged in" do
    background do
      @project = Factory(:project)
      @year = 2012
      @date = Time.new(@year, 3, 26) # An artibtrary Monday
      @date_month = @date.month
      @user_timetable = Factory(:user_timetable, :team => @team, :user => @user)
      @timetable_item = Factory(:timetable_item, :project => @project, :date => @date, :user_timetable => @user_timetable)

      visit "/"
      click_link "start-btn"
    end

    scenario "should show correct timetable item" do
      visit team_month_path(@team, @year, @date_month)
      timetable_items = backbone_collection_on_page(:timetable_items, page)

      timetable_items.length.should == 1
      timetable_items.first["id"].should == @timetable_item.id.to_s
    end
  end
end