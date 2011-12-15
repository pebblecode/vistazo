require_relative '../spec_helper'

feature "Invite user" do
  background do
    http_authorization_capybara!
    
    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    @account_id = Account.first.id
  end
  
  after do
    clean_db!
  end
  
  scenario "should send an invitation email" do
    visit "/"
    click_link "start-btn"
      
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => 'franz@gmail.com'
    end
      
    Pony.should_receive(:mail) { |params|
      params[:to].should == "franz@gmail.com"
      params[:subject].should include("You are invited to Vistazo")
        
      params[:body].should include("You've been invited to Vistazo")
      params[:body].should include("/#{@account_id}/new-user/register")
    }
    click_button 'new_user'
  end
  
  scenario "should display an error message if there is no email specified" do
    visit "/"
    click_link "start-btn"
      
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => ''
    end
    click_button 'new_user'
    
    page.should have_content("Email is not valid")
  end
  
  pending "with an existing acccount"
end
