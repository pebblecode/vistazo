require_relative '../spec_helper'

feature "Week view" do
  background do
    http_authorization_capybara!
    
    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    @user = User.first
    @team = Team.first
  end
  
  after do
    clean_db!
  end
  
  scenario "should show error message if there is an invalid team id" do
    visit "/"
    click_link "start-btn"
      
    visit team_id_current_week_path("invalid_id")
    page.should have_content("You're not authorized to view this page")
  end

  describe "after logged in" do
    background do
      @project = Factory(:project)
      @year = 2012
      @date = Time.new(@year, 3, 26) # An artibtrary Monday
      @date_week = @date.strftime("%U")
      @timetable_item = @team.add_timetable_item(@user, @project, @date)

      visit "/"
      click_link "start-btn"
    end

    scenario "should not show timetable items from other weeks" do
      @next_week_date = @date + 7.day
      @next_week_date_week = @next_week_date.strftime("%U")
      @next_week_timetable_item = @team.add_timetable_item(@user, @project, @next_week_date)
      @team.reload

      visit team_week_path(@team, @year, @date_week)
      uts = backbone_collection_on_page(:user_timetables, page)
      
      # debugger

      uts.first["timetable_items"].length.should == 1
      uts.first["timetable_items"].first["id"].should == @timetable_item.id.to_s

      visit team_week_path(@team, @year, @next_week_date_week)
      next_week_uts = backbone_collection_on_page(:user_timetables, page)
      next_week_uts.first["timetable_items"].length == 1      
      next_week_uts.first["timetable_items"].first["id"].should == @next_week_timetable_item.id.to_s
    end
  end
end
