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
    
    page.should have_content("Invitation email has been sent")
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
  
  scenario "with an existing acccount should give you an error" do
    # Create super admin
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:super_admin] }
    
    visit "/"
    click_link "start-btn" # Logs in as normal user by default
    
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => OmniAuth.config.mock_auth[:super_admin]["info"]["email"]
    end
    click_button 'new_user'
    
    page.should have_content("Sorry, user already has an account. Multiple accounts for a user is an upcoming feature we're working. Please check back again.")
  end
  
  scenario "resend email should send invitation email" do
    visit "/"
    click_link "start-btn"
      
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => 'franz@gmail.com'
    end
    click_button 'new_user'
    
    page.should have_content("Invitation email has been sent")
    
    Pony.should_receive(:mail) { |params|
      params[:to].should == "franz@gmail.com"
      params[:subject].should include("You are invited to Vistazo")
        
      params[:body].should include("You've been invited to Vistazo")
      params[:body].should include("/#{@account_id}/new-user/register")
    }
    click_link 'resend'
    
    page.should have_content("Invitation email has been sent")
  end
  
  scenario "Failed email send should show error message" do
    pending "It looks like something went wrong while attempting to send your email"
  end
end
