require_relative '../spec_helper'

describe "Team model" do
  before do
    @team = Factory(:team)
    @user = Factory(:user)
    @project = Factory(:project)
  end

  after do
    clean_db!
  end

  describe "add user" do
    before do
      @team.add_user(@user)
    end

    it "should add team to user teams" do
      @user.team_ids.include?(@team.id).should == true
    end

    it "should add to team user timetables with no timetable items" do
      user_timetables = @team.user_timetables.find_all { |ut| ut.user_id == @user.id }
      user_timetables.length.should == 1

      user_timetable = user_timetables.first
      user_timetable.user_id.should == @user.id
      user_timetable.timetable_items.length.should == 0
    end
  end

  describe "add user, user timetable is_visible" do
    it "should set is_visible to true by default" do
      @team.add_user(@user)
      @team.user_timetable(@user).is_visible.should == true
    end

    it "should set is_visible to true if explicitly passed" do
      @team.add_user(@user, true)
      @team.user_timetable(@user).is_visible.should == true
    end

    it "should set is_visible to false if explicitly passed" do
      @team.add_user(@user, false)
      @team.user_timetable(@user).is_visible.should == false
    end
  end

  describe "delete user" do
    before do
      @team.add_user(@user)
      @team.delete_user(@user)
      @team.reload
      @user.reload
    end

    it "should delete user team from user" do
      @user.team_ids.include?(@team.id).should == false
    end

    it "should delete user timetables from team" do
      user_timetables = @team.user_timetables.find_all { |ut| ut.user_id == @user.id }
      user_timetables.length.should == 0
    end
  end

  describe "user_timetable" do
    before do
      @team.add_user(@user)
      @timetable_item = @team.add_timetable_item(@user, @project, Time.now)
    end

    it "should return the correct user timetable" do
      user_timetable = @team.user_timetable(@user)

      user_timetable.user.should == @user
      user_timetable.timetable_items.should == [@timetable_item]
    end
  end

  describe "set_user_timetable_is_visible" do
    before do
      @team.add_user(@user)
    end

    it "should set it for true" do
      @team.set_user_timetable_is_visible(@user, true)
      @team.reload

      @team.user_timetable(@user).is_visible.should == true
    end

    it "should set it for false" do
      @team.set_user_timetable_is_visible(@user, false)
      @team.reload

      @team.user_timetable(@user).is_visible.should == false
    end
  end

  describe "delete project in timetables" do
    before do
      @timetable_item = @team.add_timetable_item(@user, @project, Time.now)
    end

    it "should remove project from user_timetable" do
      ut = @team.user_timetable(@user)
      ut.timetable_items.length.should == 1

      @team.delete_project_in_timetables!(@project)
      ut.timetable_items.length.should == 0

    end
  end

  describe "user_timetable" do
    it "should reference the user" do
      tti = @team.add_timetable_item(@user, @project, Time.now)
      ut = @team.user_timetable(@user)

      ut.user_id.should == @user.id
    end
  end
end