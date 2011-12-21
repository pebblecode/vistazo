require_relative '../spec_helper'

feature "Invite user" do
  background do
    http_authorization_capybara!
    
    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    @team_id = Team.first.id
  end
  
  after do
    clean_db!
  end
  
  scenario "should send an invitation email" do
    visit "/"
    click_link "start-btn"
      
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => 'franz@gmail.com'
      
      Pony.should_receive(:mail) { |params|
        params[:to].should == "franz@gmail.com"
        params[:subject].should include("You are invited to Vistazo")
        
        params[:body].should include("You've been invited to Vistazo")
        params[:body].should include("/#{@team_id}/new-user/register")
      }
      click_button 'new_user'
    end
    
    page.should have_content("Invitation email has been sent")
  end
  
  scenario "should display an error message if there is no email specified" do
    visit "/"
    click_link "start-btn"
      
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => ''
      click_button 'new_user'
    end
    
    page.should have_content("Email is not valid")
  end
  
  scenario "with an existing acccount elsewhere should work" do
    # Create super admin
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:super_admin] }
    
    # Log in as normal user (default)
    visit "/"
    click_link "start-btn"
    
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => OmniAuth.config.mock_auth[:super_admin]["info"]["email"]
      click_button 'new_user'
    end
    page.should have_content("Invitation email has been sent")
  end
  
  scenario "who has already been invited and is awaiting registration should give you an error" do
    visit "/"
    click_link "start-btn"
    
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => "now.now@gmail.com"
      click_button 'new_user'
    end
    
    page.should have_content("Invitation email has been sent")
    
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => "now.now@gmail.com"
    end
    click_button 'new_user'

    page.should have_content("User has already been sent an invitation email.")
  end
  
  scenario "who is already registered to the team should give you an error" do
    visit "/"
    click_link "start-btn"
    
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => OmniAuth.config.mock_auth[:normal_user]["info"]["email"]
      click_button 'new_user'
    end

    page.should have_content("User is already registered to this team.")
  end
  
  scenario "resend email should send invitation email" do
    visit "/"
    click_link "start-btn"
      
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => 'franz@gmail.com'
      click_button 'new_user'
    end
    
    page.should have_content("Invitation email has been sent")
    
    Pony.should_receive(:mail) { |params|
      params[:to].should == "franz@gmail.com"
      params[:subject].should include("You are invited to Vistazo")
        
      params[:body].should include("You've been invited to Vistazo")
      params[:body].should include("/#{@team_id}/new-user/register")
    }
    click_button 'resend'
    
    page.should have_content("Invitation email has been sent")
  end
  
  scenario "Failed email send should show error message" do
    pending "It looks like something went wrong while attempting to send your email"
  end
end
