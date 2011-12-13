require_relative '../spec_helper'

feature "Changing a project title" do
  background do
    Capybara.app = Sinatra::Application.new
    
    http_authorization!
    @session = init_omniauth_session
    create_normal_user(@session)
  end

  scenario "Signing in with correct credentials" do
    visit '/'
    pending "Add account name field"
    within("#account-name") do
      fill_in 'Name', :with => 'Pebblezzz'
    end
    click_link 'Update'
  end
end 