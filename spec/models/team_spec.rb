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

  describe "user_timetable_items" do
    before do
      @team.add_user(@user)
      @timetable_item = @team.add_timetable_item(@user, @project, Time.now)
    end

    it "should return the correct timetable items" do
      @team.user_timetable_items(@user).should == [@timetable_item]
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

  describe "update timetable item" do
    before do
      @from_user = @user
      @to_user = Factory(:user)
      
      @team.add_user(@from_user)
      @team.add_user(@to_user)

      @timetable_item = @team.add_timetable_item(@user, @project, Time.now)
      @to_date = Time.now + 1.day

      @team.update_timetable_item(@timetable_item, @from_user, @to_user, @to_date)
      @team.reload
    end

    it "should update the date of the timetable item" do
      @team.user_timetable(@to_user).timetable_items.length.should == 1
      updated_timetable_item = @team.user_timetable(@to_user).timetable_items.first
      updated_timetable_item.date.strftime("%F").should == @to_date.strftime("%F")
    end

    it "should not have the timetable item in the from user timetable (timetable item id should be the same)" do
      timetable_item_is_in_from_user = @team.user_timetable(@from_user).timetable_items.select { |ti| ti.id.to_s == @timetable_item.id }
      timetable_item_is_in_from_user.length.should == 0

      timetable_item_is_in_to_user = @team.user_timetable(@to_user).timetable_items.select { |ti| ti.id.to_s == @timetable_item.id.to_s }
      timetable_item_is_in_to_user.length.should == 1
    end
  end

  describe "delete timetable item" do
    before do
      @timetable_item = @team.add_timetable_item(@user, @project, Time.now)
    end

    it "should create user_timetables" do
      ut = @team.user_timetable(@user)
      ut.timetable_items.length.should == 1

      @team.delete_timetable_item_with_id!(@user, @timetable_item.id)
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