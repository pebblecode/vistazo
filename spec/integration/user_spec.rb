require_relative '../spec_helper'

feature "Team member" do
  background do
    http_authorization_capybara!
    
    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    @team_id = Team.first.id
  end
  
  after do
    clean_db!
  end
  
  scenario "can be added" do
    visit "/"
    click_link "start-btn"
    
    pending("Check in js")
    within_fieldset("New team member") do
      fill_in 'new_team_member_name', :with => 'Hobo with a shotgun'
      click_button 'new_team_member'
    end
    
    page.should have_content("Successfully added 'Hobo with a shotgun'")
  end
  
  scenario "name can be edited" do
    visit "/"
    click_link "start-btn"
    
    pending("Check in js")
    # Create team member
    within_fieldset("New team member") do
      fill_in 'new_team_member_name', :with => 'Hobo with a shotgun'
      click_button 'new_team_member'
    end
    
    page.should have_content("Successfully added 'Hobo with a shotgun'")
    
    # Edit team member
    within_fieldset("Edit team member") do
      fill_in 'name', :with => 'Hobo with gouda'
      click_button 'update'
    end
    
    page.should have_content("Successfully updated team member name.")
  end
  
  scenario "name edited as empty string should show error" do
    visit "/"
    click_link "start-btn"
    
    pending("Check in js")
    # Create team member
    within_fieldset("New team member") do
      fill_in 'new_team_member_name', :with => 'Hobo with a shotgun'
      click_button 'new_team_member'
    end
    page.should have_content("Successfully added 'Hobo with a shotgun'")
    
    # Edit team member
    within_fieldset("Edit team member") do
      fill_in 'name', :with => ''
      click_button 'update'
    end
    
    page.should have_content("Please specify a team member name.")
  end
  
  scenario "can be deleted" do
    visit "/"
    click_link "start-btn"
    
    pending("Check in js")
    # Create team member
    within_fieldset("New team member") do
      fill_in 'new_team_member_name', :with => 'Hobo with a shotgun'
      click_button 'new_team_member'
    end
    page.should have_content("Successfully added 'Hobo with a shotgun'")
    
    # Delete team member
    within_fieldset("Delete team member") do
      page.should have_content("All projects associated with 'Hobo with a shotgun' will also be deleted.")
      click_button 'delete'
    end
    
    page.should have_content("Successfully deleted 'Hobo with a shotgun'")
  end
end
