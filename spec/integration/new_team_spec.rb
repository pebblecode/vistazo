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
  end
  
  describe "after pressing the new team button" do
    background do
      @new_team_name = "Yeah Yeah Yeahs"
      within ("#new-team-form") do
        fill_in 'new_team_name', :with => @new_team_name
        click_button 'new-team-button'
      end
    end
    
    scenario "should be on the new team page" do
      find("#team-name").text.should include(@new_team_name)
      page.should have_content("Successfully created team")
    end
    
    scenario "should have user as the first team member" do
      pending
    end
    
    scenario "should allow user to switch to the new team" do
      pending
    end
    
    scenario "should allow user to add others to the team" do
      pending
    end
    
    describe "with an erroneous team name" do
      pending "should show an error"
    end
  end
end