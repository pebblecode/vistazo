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

  describe "team" do
    it "should be able to be referenced" do
      team = Factory(:team, :name => "Samurai Pizza Cats")
      timetable_item = Factory(:timetable_item, :team => team)

      timetable_item.team.should == team
    end
  end

  describe "week_num" do
    it "should be cached on creation" do
      timetable_item = Factory(:timetable_item, :date => "2012-07-26")
      timetable_item.week_num.should == 30
    end

    it "should be cached on save" do
      timetable_item = Factory(:timetable_item)
      timetable_item.date = "2012-01-01"
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

  describe "self.by_team_year_week" do
    before do
      @team = Factory(:team)
      @date = Date.parse("2012-07-26")
      @year = @date.year
      @week_num = @date.strftime("%U").to_i

      @timetable_item = Factory(:timetable_item, :date => @date, :team => @team)
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