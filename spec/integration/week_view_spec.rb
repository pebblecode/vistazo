require_relative '../spec_helper'

feature "Week view" do
  background do
    http_authorization_capybara!
    
    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    @team_id = Team.first.id
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
end
