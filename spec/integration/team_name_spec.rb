require_relative '../spec_helper'

feature "Team name" do
  background do
    http_authorization_capybara!
    
    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    
  end
  
  after do
    clean_db!
  end
  
  scenario "Updating to a new name" do
    account = Account.first
    account.name = "Cat's schedule"
    account.save
    
    visit "/"
    click_link "start-btn"
    page.should have_content("Cat's schedule")
    
    within_fieldset("Team name") do
      fill_in 'team_name', :with => 'Pebblez schedule'
      click_button 'update'
    end
    
    page.should have_content("Updated team name successfully.")
    
    within("#team-name h2") do
      page.should have_content 'Pebblez schedule'
    end
  end
  
  scenario "Updating to an empty name" do
    visit "/"
    click_link "start-btn"
    
    within_fieldset("Team name") do
      fill_in 'team_name', :with => ''
      click_button 'update'
    end
    
    page.should have_content("Updated team name failed. Team name was empty.")
  end
end 