require_relative '../spec_helper'

feature "Create new team" do
  background do
    http_authorization_capybara!
    
    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    
    visit "/"
    click_link "start-btn"
  end
  
  after do
    clean_db!
    
    # Make sure default user is back to normal_user
    switch_omniauth_user :normal_user
  end
  
  describe "after pressing the new team button" do
    background do
      @new_team_name = "Yeah Yeah Yeahs"
      within ("#new-team-form") do
        fill_in 'new_team_name', :with => @new_team_name
        click_button 'new-team-button'
      end
      @new_team = Team.find_by_name(@new_team_name)
    end
    
    scenario "should be on the new team page" do
      find("#team-name").text.should include(@new_team_name)
      page.should have_content("Successfully created team")
    end
      
    scenario "should have user as the first team member" do
      pending("Check in js")
      # find(".team-member-name").text.should include(OmniAuth.config.mock_auth[:normal_user]["info"]["name"])
    end
  
    scenario "should allow user to switch between teams" do
      within("#switch-teams") do
        click_link DEFAULT_TEAM_NAME
      end
      find("#team-name").text.should include(DEFAULT_TEAM_NAME)
      
      within("#switch-teams") do
        click_link @new_team_name
      end
      find("#team-name").text.should include(@new_team_name)
    end
  
    scenario "should allow user to add others to the team" do
      within_fieldset("Invite new user") do
        fill_in 'new_user_email', :with => OmniAuth.config.mock_auth[:karen_o]["info"]["email"]
        click_button 'new_user'

        @new_user = User.find_by_email(OmniAuth.config.mock_auth[:karen_o]["info"]["email"])
        @registration_link = registration_with_team_id_and_user_id_path(@new_team.id, @new_user.id)
      end
      
      switch_omniauth_user :karen_o
      visit @registration_link
      click_link "start-btn"
      @new_team.reload
      @new_user.reload
      
      find("#team-name").text.should include(@new_team_name)
    end
  end
  
  describe "with an erroneous team name" do
    background do
      @new_team_name = ""
      within ("#new-team-form") do
        fill_in 'new_team_name', :with => @new_team_name
        click_button 'new-team-button'
      end
      @new_team = Team.find_by_name(@new_team_name)
    end
    
    scenario "should show an error" do
      page.should have_content("Create team failed. Team name empty.")
    end
  end
end