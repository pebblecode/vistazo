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
    @existing_user_email = OmniAuth.config.mock_auth[:super_admin]["info"]["email"]
    
    # Log in as normal user (default)
    visit "/"
    click_link "start-btn"
    
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => @existing_user_email
      
      email_body = ""
      Pony.should_receive(:mail) { |params|
        params[:to].should == @existing_user_email
        params[:subject].should include("You are invited to Vistazo")
        
        params[:body].should include("You've been invited to Vistazo")
        email_body = params[:body]
      }
      
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

feature "After inviting Karen O (who already has an account) from normal user's account" do
  background do
    http_authorization_capybara!
    
    # Create new user and team
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    @team = Team.first
    
    # Create Karen O account
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:karen_o] }
    @karen_o_email = OmniAuth.config.mock_auth[:karen_o]["info"]["email"]
    
    visit "/"
    click_link "start-btn"
      
    within_fieldset("Invite new user") do
      fill_in 'new_user_email', :with => @karen_o_email
      click_button 'new_user'
      
      @karen_o = User.find_by_email(@karen_o_email)
    end
    @team.reload
    
    visit logout_path
  end
  
  after do
    clean_db!
    
    # Make sure default user is back to normal_user
    switch_omniauth_user :normal_user
  end
  
  scenario "normal user should see Karen O as a pending user" do
    # Log in as normal user
    visit "/"
    click_link "start-btn"
    
    find("#team-users-dialog .pending").text.should include(@karen_o_email)
  end
  
  scenario "Karen O should not see the normal user's account if she has not registered yet" do
    # Log in as Karen O
    switch_omniauth_user :karen_o
    visit "/"
    click_link "start-btn"
    
    page.should_not have_content(@team.name)
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
      click_button 'new_user'
      
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

  scenario "should show the user's name and email in active users listing" do
    switch_omniauth_user :super_admin
    
    visit registration_with_team_id_and_user_id_path(@team.id, @new_user.id)
    click_link "start-btn"
    
    @new_user.reload
    find("#team-users-dialog .listing.active").text.should include(@new_user.name)
    find("#team-users-dialog .listing.active").text.should include(@new_user.email)
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
  
  describe "for existing users" do
    before do
      @existing_user = User.find_by_email(omniauth_email(:normal_user))
      @existing_user.present?.should == true

      # Create new user and team
      get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:karen_o] }
      @another_user_team = User.find_by_email(omniauth_email(:karen_o)).teams.first
      @another_user_team.present?.should == true
      
      @another_user_team.has_pending_user?(@existing_user).should == false
      @another_user_team.has_active_user?(@existing_user).should == false

      switch_omniauth_user :karen_o
      visit "/"
      click_link "start-btn"

      within_fieldset("Invite new user") do
        fill_in 'new_user_email', :with => @existing_user.email
        click_button 'new_user'
      end
      @another_user_team.reload

      @another_user_team.has_pending_user?(@existing_user).should == true
      @another_user_team.has_active_user?(@existing_user).should == false

      switch_omniauth_user :normal_user
      visit registration_with_team_id_and_user_id_path(@another_user_team.id, @existing_user.id)
      click_link "start-btn"

      @another_user_team.reload
    end
    
    scenario "should activate them in the team (ie, change status from pending to active)" do
      @another_user_team.has_pending_user?(@existing_user).should == false
      @another_user_team.has_active_user?(@existing_user).should == true
    end
    
    scenario "should be able to switch teams" do
      find("#switch-teams").text.should include(@team.name)
      find("#switch-teams").text.should include(@another_user_team.name)

      within ("#switch-teams") do
        click_link @another_user_team.name
      end
      should_be_on_team_name_page(@another_user_team.name)

      within ("#switch-teams") do
        click_link @team.name
      end
      should_be_on_team_name_page(@team.name)
    end
  end
  
  scenario "should log user into team page" do
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
  
  scenario "and visiting registration again, should not add the user again" do
    visit registration_with_team_id_and_user_id_path(@team.id, @new_user.id)
    click_link "start-btn"
    
    @new_user.reload
    @team.reload
    find("#team-users-dialog .listing.active").text.scan(@new_user.email).count.should == 1
    
    visit registration_with_team_id_and_user_id_path(@team.id, @new_user.id)
    click_link "start-btn"
    
    @new_user.reload
    @team.reload
    find("#team-users-dialog .listing.active").text.scan(@new_user.email).count.should == 1
  end
  
  it "visiting registration page after registering should say that you have registered already" do
    pending "implement this"
  end
end
