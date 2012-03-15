require_relative '../spec_helper'

describe "Team model" do
  after do
    clean_db!
  end
  
  describe "add user" do
    before do
      @team = Factory(:team)
      @user = Factory(:user)
    end
    
    it "should add team to user teams" do
      @team.add_user(@user)
      @user.team_ids.include?(@team.id).should == true
    end
  end

  describe "add timetable item" do
    before do
      @team = Factory(:team)
      @user = Factory(:user)
      @project = Factory(:project)
    end
    
    it "should add into the user timetable items" do
      tti = @team.add_timetable_item(@user, @project, Time.now)
      
      @team.user_timetables.length.should == 1
      user_timetable = @team.user_timetables.first

      user_timetable.timetable_items.length.should == 1
      user_timetable.timetable_items.first.should == tti
    end
  end
end