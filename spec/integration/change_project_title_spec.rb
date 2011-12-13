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
    
    pending "change title text boxes"
    within("#account-name") do
      fill_in 'Name', :with => 'Pebblezzz schedule'
    end
    click_button 'Update'
    
    within("#account-name") do
      page.should have_content 'Pebblezzz schedule'
    end
  end
end 