require_relative '../spec_helper'

describe "TimetableItem model" do
  after do
    clean_db!
  end

  describe "css_class" do
    it "is of the form 'project-[downcased and stripped id]'" do
      project = Factory(:project, :id => "SOME!@id-of-some-sort")
      project.css_class.should == "project-some--id-of-some-sort"
    end
  end

  describe "project" do
    it "should be able to be referenced" do
      project = Factory(:project, :name => "vistazo")
      timetable_item = Factory(:timetable_item, :project => project)

      timetable_item.project.should == project
    end
  end

  describe "project name" do
    it "should be cached" do
      project = Factory(:project, :name => "vistazo")
      timetable_item = Factory(:timetable_item, :project => project)

      timetable_item.project_name.should == "vistazo"
    end
  end

  describe "user timetable" do
    it "should cache team on creation" do
      user_timetable = Factory(:user_timetable)
      timetable_item = Factory(:timetable_item, :user_timetable => user_timetable)

      timetable_item.team_id.should == user_timetable.team_id
    end

    it "should cache team on save" do
      timetable_item = Factory(:timetable_item)
      user_timetable = Factory(:user_timetable)
      timetable_item.user_timetable = user_timetable
      timetable_item.save

      timetable_item.team_id.should == user_timetable.team_id
    end

    it "should cache user on creation" do
      user_timetable = Factory(:user_timetable)
      timetable_item = Factory(:timetable_item, :user_timetable => user_timetable)

      timetable_item.user.should == user_timetable.user
    end

    it "should cache user on save" do
      timetable_item = Factory(:timetable_item)
      user_timetable = Factory(:user_timetable)
      timetable_item.user_timetable = user_timetable
      timetable_item.save

      timetable_item.user.should == user_timetable.user
    end
  end

  describe "week_num" do
    it "should be cached on creation" do
      timetable_item = Factory(:timetable_item, :date => "2012-07-26")
      timetable_item.week_num.should == 30
    end

    it "should be cached on save" do
      timetable_item = Factory(:timetable_item)
      timetable_item.date = "2012-01-05"
      timetable_item.save

      timetable_item.week_num.should == 1
    end
  end

  describe "year" do
    it "should be cached on creation" do
      timetable_item = Factory(:timetable_item, :date => "2012-07-26")
      timetable_item.year.should == 2012
    end

    it "should be cached on save" do
      timetable_item = Factory(:timetable_item)
      timetable_item.date = "2011-01-01"
      timetable_item.save

      timetable_item.year.should == 2011
    end
  end

  describe "month" do
    it "should be cached on creation" do
      timetable_item = Factory(:timetable_item, :date => "2012-07-26")
      timetable_item.month.should == 7
    end

    it "should be cached on save" do
      timetable_item = Factory(:timetable_item)
      timetable_item.date = "2011-01-01"
      timetable_item.save

      timetable_item.month.should == 1
    end
  end

  describe "self.create_with_team_id_and_user_id" do
    before do
      @user_timetable = Factory(:user_timetable)
      @team = @user_timetable.team
      @user = @user_timetable.user
      @project = Factory(:project)

      @date = Date.parse("2012-07-26")
    end

    it "should save timetable item" do
      timetable_item = TimetableItem.create_with_team_id_and_user_id(@team.id, @user.id, {
          :project => @project,
          :date => @date
        })

      timetable_item.nil?.should == false
      TimetableItem.count.should == 1
    end

    it "should save team" do
      timetable_item = TimetableItem.create_with_team_id_and_user_id(@team.id, @user.id, {
          :project => @project,
          :date => @date
        })

      timetable_item.team.should == @team
    end

    it "should save user" do
      timetable_item = TimetableItem.create_with_team_id_and_user_id(@team.id, @user.id, {
          :project => @project,
          :date => @date
        })

      timetable_item.user.should == @user
    end

    it "should save user_timetable" do
      timetable_item = TimetableItem.create_with_team_id_and_user_id(@team.id, @user.id, {
          :project => @project,
          :date => @date
        })

      timetable_item.user_timetable.should == @user_timetable
    end

    it "should not save timetable item if not in right team" do
      another_team = Factory(:team)
      timetable_item = TimetableItem.create_with_team_id_and_user_id(another_team.id, @user.id, {
          :project => @project,
          :date => @date
        })

      timetable_item.nil?.should == true
      TimetableItem.count.should == 0
    end

    it "should not save timetable item if not in right user" do
      another_user = Factory(:user)
      timetable_item = TimetableItem.create_with_team_id_and_user_id(@team.id, another_user.id, {
          :project => @project,
          :date => @date
        })

      timetable_item.nil?.should == true
      TimetableItem.count.should == 0
    end
  end

  describe "self.by_team_year_week" do
    before do
      user_timetable = Factory(:user_timetable)
      @team = user_timetable.team
      @date = Date.parse("2012-07-26")
      @year = @date.year
      @week_num = Date.week_num(@date).to_i

      @timetable_item = Factory(:timetable_item, :date => @date, :user_timetable => user_timetable)
    end

    it "should find timetable item" do
      TimetableItem.by_team_year_week(@team, @year, @week_num).count.should == 1
    end

    it "should not find timetable item for the wrong team" do
      another_team = Factory(:team)

      TimetableItem.by_team_year_week(another_team, @year, @week_num).count.should == 0
    end

    it "should not find timetable item for the wrong year" do
      new_year = @year - 1

      TimetableItem.by_team_year_week(@team, new_year, @week_num).count.should == 0
    end

    it "should not find timetable item for the wrong week num" do
      new_week_num = @week_num - 1

      TimetableItem.by_team_year_week(@team, @year,new_week_num).count.should == 0
    end
  end
end