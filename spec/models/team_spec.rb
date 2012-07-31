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
      @user_timetable = UserTimetable.find_by_user_id(@user.id)
    end

    it "should add team to user teams" do
      @user.team_ids.include?(@team.id).should == true
    end

    it "should add to team user timetables with no timetable items" do
      user_timetables = UserTimetable.where({:user_id => @user.id})
      user_timetables.count.should == 1

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

  describe "delete user in team" do
    before do
      @team.add_user(@user)
    end

    describe "upon deletion" do
      before do
        @team.delete_user(@user)
        @team.reload
        @user.reload
      end

      it "should delete user team from user" do
        @user.team_ids.include?(@team.id).should == false
      end

      it "should delete user timetables from team" do
        user_timetables = UserTimetable.where({:user_id => @user.id})
        user_timetables.count.should == 0
      end
    end

    it "should delete timetable items for user" do
      user_timetable = Factory(:user_timetable, :user_id => @user.id, :team_id => @team.id)
      timetable_item = Factory(:timetable_item, :user_timetable => user_timetable)
      user_timetable_items = TimetableItem.where({:user_timetable_id => user_timetable.id})

      user_timetable_items.count.should == 1
      @team.delete_user(@user)
      user_timetable_items.count.should == 0
    end

    describe "with other teams" do
      before do
        @another_team = Factory(:team)
        @another_team.add_user(@user)
        @user.reload
      end

      describe "upon deletion" do
        before do
          @user_timetables = UserTimetable.where({:user_id => @user.id})
          @user_timetables.count.should == 2

          @team.delete_user(@user)
          @user.reload
        end

        it "should not delete other teams from user" do
          @user.teams.count.should == 1
          @user.teams.first.should == @another_team
        end

        it "should not delete user user_timetables from other teams" do
          @user_timetables.count.should == 1
          @user_timetables.first.team.should == @another_team
        end
      end

      it "should not delete timetable items for user in other teams" do
        user_timetable = UserTimetable.find_by_team_id(@team.id)
        Factory(:timetable_item, :user_timetable => user_timetable)

        another_user_timetable = UserTimetable.find_by_team_id(@another_team.id)
        Factory(:timetable_item, :user_timetable => another_user_timetable)

        TimetableItem.count.should == 2
        @team.delete_user(@user)
        @user.reload
        TimetableItem.count.should == 1
      end

      it "should not delete timetable items for other users in team" do
        # User timetable
        user_timetable = UserTimetable.find_by_user_id(@user.id)
        Factory(:timetable_item, :user_timetable => user_timetable)

        # Another user timetable
        another_user = Factory(:user)
        @team.add_user(another_user)
        another_user.reload
        another_user_timetable = UserTimetable.find_by_user_id(another_user.id)
        Factory(:timetable_item, :user_timetable => another_user_timetable)

        TimetableItem.count.should == 2
        @team.delete_user(@user)
        @user.reload
        TimetableItem.count.should == 1
      end
    end
  end

  describe "user_timetable" do
    before do
      @team.add_user(@user)
      @user_timetable = UserTimetable.find_by_user_id(@user.id)
    end

    it "should return the correct user timetable" do
      user_timetable = @team.user_timetable(@user)

      user_timetable.user.should == @user
      user_timetable.team.should == @team
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
      @team.add_user(@user)
      @user_timetable = UserTimetable.find_by_user_id(@user.id)
      @timetable_item = Factory(:timetable_item, :user_timetable => @user_timetable, :project => @project, :date => Time.now)

      TimetableItem.count.should == 1
      Project.count.should == 1
    end

    describe "upon deletion" do
      before do
        @team.delete_project_in_timetables!(@project)
      end

      it "should remove all timetable items in team and project" do
        TimetableItem.count.should == 0
      end

      it "should remove project" do
        Project.count.should == 0
      end
    end

    it "should not remove other projects in the team" do
      another_project = Factory(:project)
      @timetable_item = Factory(:timetable_item, :user_timetable => @user_timetable, :project => another_project, :date => Time.now)
      Project.count.should == 2

      @team.delete_project_in_timetables!(@project)
      Project.count.should == 1
    end
  end

  describe "user_timetable" do
    it "should reference the user" do
      @team.add_user(@user)
      @timetable_item = Factory(:timetable_item, :user_timetable => @user_timetable, :project => @project, :date => Time.now)
      tti = Factory(:timetable_item, :user_timetable => @user_timetable, :project => @project, :date => Time.now)
      ut = @team.user_timetable(@user)

      ut.user_id.should == @user.id
    end
  end
end