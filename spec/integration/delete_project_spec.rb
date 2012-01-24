require_relative '../spec_helper'

feature "Delete project" do
  background do
    http_authorization_capybara!
    
    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    @team = Team.first
    @team_member = TeamMember.first
    
    @date = Time.now
    
    # Can't seem to create a project with factory girl, with team association (can't reference it even after creation)
    # @project = Factory.build(:project, :name => "Business time", :team => @team)
    @project = Project.create(:name => "Business time", :team_id => @team.id)
    @team_member.add_project_on_date(@project, @date)
    Project.count.should == 1
    
    visit "/"
    click_link "start-btn"
  end
  
  after do
    clean_db!
  end
  
  pending "require login"
  
  pending "should show warning message before delete"
  
  scenario "should delete a project from existing projects list" do
    within_fieldset("Add a project") do
      find_button("Business time")
      click_button "delete"
    end
    
    # Shouldn't be in add a project or in timetable
    page.should_not have_content("Business time")
  end
  
  scenario "should delete all project timetable items" do
    pending "Check on other pages too"
  end
end