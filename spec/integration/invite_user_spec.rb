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
      email_body.should include(registration_with_team_id_and_user_id_path(@team.id, @new_user.id))
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
    email_body.should include(registration_with_team_id_and_user_id_path(@team.id, @new_user.id))
    
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
      email_body.should include(registration_with_team_id_and_user_id_path(@team.id, @new_user.id))
    end
    @team.reload
    
    visit logout_path
  end
  
  after do
    clean_db!
  end
  
  scenario "should show welcome message and activation link" do
    visit registration_with_team_id_and_user_id_path(@team.id, @new_user.id)
    page.body.should include("You have been invited to join <span>#{@team.name}</span> on Vistazo")
    page.body.should include(activation_with_team_id_and_user_id_path(@team.id, @new_user.id))
  end
  
  scenario "with an invalid user id should show error message" do
    user_id = "wrong_id"
    visit registration_with_team_id_and_user_id_path(@team.id, user_id)
    page.body.should include("Invalid user")
    page.current_path.should == "/"
  end
  
  scenario "with an invalid team id should show error message" do
    team_id = "wrong_id"
    visit registration_with_team_id_and_user_id_path(team_id, @new_user.id)
    page.body.should include("Invalid team")
    page.current_path.should == "/"
  end
  
  scenario "should not activate user" do
    @team.has_pending_user?(@new_user).should == true
    @team.has_active_user?(@new_user).should == false
    
    visit registration_with_team_id_and_user_id_path(@team.id, @new_user.id)
    
    # Should not activate user yet
    @team.reload
    @team.has_pending_user?(@new_user).should == true
    @team.has_active_user?(@new_user).should == false
  end
end

feature "After going on the registration page and clicking on the activation button" do
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
    end
    @team.reload
    
    visit logout_path
  end
  
  after do
    clean_db!
    
    # Make sure default user is back to normal_user
    switch_omniauth_user :normal_user
  end

  scenario "should show the user's email" do
    visit registration_with_team_id_and_user_id_path(@team.id, @new_user.id)
    page.body.should include(@new_user_email)
  end

  scenario "with an invalid user id should show error message" do
    user_id = "wrong_id"
    visit registration_with_team_id_and_user_id_path(@team.id, user_id)
    page.body.should include("Invalid user")
    page.current_path.should == "/"
  end
  
  scenario "with an invalid team id should show error message" do
    team_id = "wrong_id"
    visit registration_with_team_id_and_user_id_path(team_id, @new_user.id)
    page.body.should include("Invalid team")
    page.current_path.should == "/"
  end
  
  scenario "should activate new user once they click the activate button (ie, change status from pending to active)" do
    @team.has_pending_user?(@new_user).should == true
    @team.has_active_user?(@new_user).should == false
    
    visit registration_with_team_id_and_user_id_path(@team.id, @new_user.id)
    click_link "start-btn"
    
    @team.reload
    @team.has_pending_user?(@new_user).should == false
    @team.has_active_user?(@new_user).should == true
  end
  
  pending "should activate existing user once they click the activate button (ie, change status from pending to active)" do
    
  end
  
  scenario "should log in user into team page" do
    switch_omniauth_user :super_admin
    
    visit registration_with_team_id_and_user_id_path(@team.id, @new_user.id)
    click_link "start-btn"
    
    @new_user.reload
    should_be_logged_in_as_username @new_user.name
    should_be_on_team_name_page(@team.name)
  end
  
  scenario "should not log into team if logged in as someone else (should just go to the other person's team page)" do
    switch_omniauth_user :karen_o
    
    visit registration_with_team_id_and_user_id_path(@team.id, @new_user.id)
    click_link "start-btn"
    
    @new_user.reload
    should_be_logged_in_as_username omniauth_user_name :karen_o
    should_not_be_on_team_name_page(@team.name)
    should_be_on_team_name_page("#{omniauth_user_name(:karen_o)}'s team")
  end
  
  scenario "should not activate user for team if logged in as someone else" do
    switch_omniauth_user :karen_o
    
    visit registration_with_team_id_and_user_id_path(@team.id, @new_user.id)
    click_link "start-btn"
    
    @new_user.reload
    @team.has_pending_user?(@new_user).should == true
    @team.has_active_user?(@new_user).should == false
  end
  
  scenario "and visiting registration again, should not add the user twice" do
    visit registration_with_team_id_and_user_id_path(@team.id, @new_user.id)
    click_link "start-btn"
    
    @new_user.reload
    @team.reload
    
    @team.active_users.select {|u| u["email"] == @new_user.email }.count.should == 1
    visit registration_with_team_id_and_user_id_path(@team.id, @new_user.id)
    click_link "start-btn"
    
    @new_user.reload
    @team.reload
    @team.active_users.select {|u| u["email"] == @new_user.email }.count.should == 1
  end
  
  pending "visiting registration page after registering should say that you have registered already" do
    
  end
end
