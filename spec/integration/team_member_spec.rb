require_relative '../spec_helper'

feature "Team member" do
  background do
    http_authorization_capybara!
    
    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    @account_id = Account.first.id
  end
  
  after do
    clean_db!
  end
  
  scenario "can be added" do
    visit "/"
    click_link "start-btn"
      
    within_fieldset("New team member") do
      fill_in 'new_team_member_name', :with => 'Hobo with a shotgun'
    end
    click_button 'new_team_member'
    
    page.should have_content("Successfully added 'Hobo with a shotgun'")
  end
  
end
