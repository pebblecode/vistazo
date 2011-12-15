require_relative '../spec_helper'

feature "Account name" do
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
    
    within_fieldset("Account name") do
      fill_in 'account_name', :with => 'Pebblez schedule'
    end
    click_button 'update'
    page.should have_content("Updated account name successfully.")
    
    within("#account-name h2") do
      page.should have_content 'Pebblez schedule'
    end
  end
  
  scenario "Updating to an empty name" do
    visit "/"
    click_link "start-btn"
    
    within_fieldset("Account name") do
      fill_in 'account_name', :with => ''
    end
    click_button 'update'
    page.should have_content("Updated account name failed. Account name was empty.")
  end
end 