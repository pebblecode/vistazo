require_relative '../spec_helper'

feature "Invite user" do
  background do
    http_authorization_capybara!
    
    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    @team = Team.first
  end
  
  after do
    clean_db!
  end
  
  scenario "should send an invitation email" do
    @new_user_email = OmniAuth.config.mock_auth[:super_admin]["info"]["email"]
    
    visit "/"
    click_link "start-btn"
      
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => @new_user_email
      
      email_body = ""
      Pony.should_receive(:mail) { |params|
        params[:to].should == @new_user_email
        params[:subject].should include("You are invited to Vistazo")
        
        params[:body].should include("You've been invited to Vistazo")
        email_body = params[:body]
      }
      click_button 'new_user'
      
      # Can only check the registration link after user is created
      @new_user = User.find_by_email(@new_user_email)
      @new_user.present?.should == true
      email_body.should include("/#{@team.id}/user/#{@new_user.id}/register")
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
    @new_user_email = OmniAuth.config.mock_auth[:super_admin]["info"]["email"]
    
    visit "/"
    click_link "start-btn"
    
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => @new_user_email
      click_button 'new_user'
      
      # Can only check the registration link after user is created
      @new_user = User.find_by_email(@new_user_email)
      @new_user.present?.should == true
    end
    
    page.should have_content("Invitation email has been sent")
    
    # Resend email
    email_body = ""
    Pony.should_receive(:mail) { |params|
      params[:to].should == @new_user_email
      params[:subject].should include("You are invited to Vistazo")
      
      params[:body].should include("You've been invited to Vistazo")
      email_body = params[:body]
    }
    click_button 'resend'
    email_body.should include("/#{@team.id}/user/#{@new_user.id}/register")
    
    page.should have_content("Invitation email has been sent")
  end
  
  scenario "Failed email send should show error message" do
    pending "It looks like something went wrong while attempting to send your email"
  end
end

feature "After getting the invitation email, registration page" do
  background do
    http_authorization_capybara!
    
    # Create new user and team
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    @team = Team.first
    
    @new_user_email = OmniAuth.config.mock_auth[:super_admin]["info"]["email"]
    
    visit "/"
    click_link "start-btn"
      
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => @new_user_email
      
      email_body = ""
      Pony.should_receive(:mail) { |params|
        email_body = params[:body]
      }
      click_button 'new_user'
      
      # Can only check the registration link after user is created
      @new_user = User.find_by_email(@new_user_email)
      @new_user.present?.should == true
      email_body.should include("/#{@team.id}/user/#{@new_user.id}/register")
    end
    @team.reload
    
    visit logout_path
  end
  
  after do
    clean_db!
  end
  
  scenario "should change new users from pending to active in team" do
    @team.has_pending_user?(@new_user).should == true
    @team.has_active_user?(@new_user).should == false
    
    visit "/#{@team.id}/user/#{@new_user.id}/register"
    
    @team.has_pending_user?(@new_user).should == false
    @team.has_active_user?(@new_user).should == true
  end
  
  pending "should change existing users from pending to active in team"
  
end
