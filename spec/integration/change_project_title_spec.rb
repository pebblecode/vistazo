require_relative '../spec_helper'

feature "Project title" do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  background do
    Capybara.app = VistazoApp
    
    http_authorization_capybara!
    
    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    
  end

  scenario "Changing project title" do
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
    page.should have_content("Updated account name.")
    
    within("#account-name h2") do
      page.should have_content 'Pebblez schedule'
    end
  end
end 