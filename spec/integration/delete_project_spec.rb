require_relative '../spec_helper'

feature "Delete project" do
  background do
    http_authorization_capybara!
    
    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    @team = Team.first
    @team_member = TeamMember.first
    
    # Can't seem to create a project with factory girl, with team association (can't reference it even after creation)
    # @project = Factory.build(:project, :name => "Business time", :team => @team)
    @project = Project.create(:name => "Business time", :team_id => @team.id)
    Project.count.should == 1
  end
  
  after do
    clean_db!
  end
  
  scenario "should delete a project from new projects list" do
    pending "Do js test"
    # visit "/"
    # click_link "start-btn"
    # within("#delete-project-dialog") do
    #   click_button "delete"
    # end
    
    # page.should have_content("Successfully deleted project '#{@project.name}'")
    
    # within("#new-project-dialog") do
    #   page.should_not have_content("Business time")
    # end
  end
  
  scenario "should delete all project timetable items in week view" do
    pending "Do js test"
    # @date = Time.now
    # @team_member.add_project_on_date(@project, @date)
    
    # visit "/"
    # click_link "start-btn"
    
    # page.should have_content("Business time")
    
    # within("#delete-project-dialog") do
    #   click_button "delete"
    # end
    
    # within("#week-view") do
    #   page.should_not have_content("Business time")
    # end
  end
  
  scenario "should delete all project timetable items in multiple weeks" do
    pending "Do js test"
    @date = Time.now
    
    # # Add project for this week and next
    # @team_member.add_project_on_date(@project, @date)
    # @team_member.add_project_on_date(@project, @date + 7.day)
    
    # # Check project was added
    # visit "/"
    # click_link "start-btn"
    # within("#week-view") do
    #   page.should have_content("Business time")
    # end
    
    # click_link "Next week"
    # within("#week-view") do
    #   page.should have_content("Business time")
    # end
    
    # # Delete project
    # within("#delete-project-dialog") do
    #   click_button "delete"
    # end
    
    # # Check project was deleted from week views
    # visit "/"
    # within("#week-view") do
    #   page.should_not have_content("Business time")
    # end
    
    # click_link "Next week"
    # within("#week-view") do
    #   page.should_not have_content("Business time")
    # end
    
  end
end