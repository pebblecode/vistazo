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
    @session = nil
  end

  scenario "should show error message if there is an invalid team id" do
    visit "/"
    click_link "start-btn"

    visit team_id_current_week_path("invalid_id")
    page.should have_content("You're not authorized to view this page")
  end

  describe "after logged in, in the first week of a year" do
    background do
      @project = Factory(:project)
      @year = 2013
      @date = Time.new(@year, 1, 1)
      @date_week = Date.week_num(@date)

      @user_timetable = Factory(:user_timetable, :team => @team, :user => @user)
      @timetable_item = Factory(:timetable_item, :project => @project, :date => @date, :user_timetable => @user_timetable)

      visit "/"
      click_link "start-btn"

      visit team_week_path(@team, @year, @date_week)
    end

    scenario "should show timetable item added" do
      timetable_items = backbone_collection_on_page(:timetable_items, page)

      timetable_items.length.should == 1
    end
  end

  describe "after logged in" do
    background do
      @project = Factory(:project)
      @year = 2012
      @date = Time.new(@year, 3, 26) # An artibtrary Monday
      @date_week = Date.week_num(@date)
      @user_timetable = Factory(:user_timetable, :team => @team, :user => @user)
      @timetable_item = Factory(:timetable_item, :project => @project, :date => @date, :user_timetable => @user_timetable)

      visit "/"
      click_link "start-btn"
    end

    scenario "should show correct timetable items from different weeks" do
      next_week_date = @date + 7.day
      next_week_date_week = Date.week_num(next_week_date)
      next_week_timetable_item = Factory(:timetable_item, :user_timetable => @user_timetable, :project => @project, :date => next_week_date)

      visit team_week_path(@team, @year, @date_week)
      timetable_items = backbone_collection_on_page(:timetable_items, page)

      timetable_items.length.should == 1
      timetable_items.first["id"].should == @timetable_item.id.to_s

      visit team_week_path(@team, @year, next_week_date_week)
      next_week_timetable_items = backbone_collection_on_page(:timetable_items, page)
      next_week_timetable_items.length == 1
      next_week_timetable_items.first["id"].should == next_week_timetable_item.id.to_s
    end

    scenario "should show correct timetable items for multiple users" do
      another_user = Factory(:user)
      another_user_user_timetable = Factory(:user_timetable, :user => another_user, :team => @team)
      another_user_user_timetable_item = Factory(:timetable_item, :user_timetable => another_user_user_timetable, :project => @project, :date => @date)

      visit team_week_path(@team, @year, @date_week)
      timetable_items = backbone_collection_on_page(:timetable_items, page)

      timetable_items.length.should == 2

      timetable_item_ids = timetable_items.map{|tti| tti["id"]}
      timetable_item_ids.include?(@timetable_item.id.to_s).should == true
      timetable_item_ids.include?(another_user_user_timetable_item.id.to_s).should == true

    end
  end
end
