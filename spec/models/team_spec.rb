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
    it "should add team to user teams" do
      @team.add_user(@user)
      @user.team_ids.include?(@team.id).should == true
    end

    it "should add to team user timetables with no timetable items" do
      @team.add_user(@user)

      user_timetables = @team.user_timetables.find_all { |ut| ut.user_id == @user.id }
      user_timetables.length.should == 1

      user_timetable = user_timetables.first
      user_timetable.user_id.should == @user.id
      user_timetable.timetable_items.length.should == 0
    end
  end

  describe "add timetable item" do
    it "should create user_timetables" do
      @team.add_timetable_item(@user, @project, Time.now)

      @team.user_timetables.length.should == 1
    end

    it "should add into the user timetable items" do
      tti = @team.add_timetable_item(@user, @project, Time.now)
      user_timetable = @team.user_timetables.first

      user_timetable.timetable_items.length.should == 1
      user_timetable.timetable_items.first.should == tti
    end

    it "should reference user and team in added user timetable" do
      @team.add_timetable_item(@user, @project, Time.now)
      user_timetable = @team.user_timetables.first

      user_timetable.team_id.should == @team.id
      user_timetable.user_id.should == @user.id
    end
  end

  describe "delete timetable item" do
    it "should create user_timetables" do
      timetable_item = @team.add_timetable_item(@user, @project, Time.now)
      @team.delete_timetable_item_with_id!(@user, timetable_item.id)

      ut = @team.user_timetable(@user)
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

  describe "add multiple timetable items" do
    it "should add them into the user timetable items" do
      @team.add_timetable_item(@user, Factory(:project), Time.now)
      @team.add_timetable_item(@user, Factory(:project), Time.now)
      @team.add_timetable_item(@user, Factory(:project), Time.now)

      @team.user_timetable(@user).timetable_items.length.should == 3
    end

    it "should not add the user multiple times" do
      @team.add_timetable_item(@user, @project, Time.now)
      @team.add_timetable_item(@user, @project, Time.now)

      @team.user_timetables.length.should == 1
    end
  end
end