require_relative '../spec_helper'

describe "TimetableItem model" do
  before do
    
  end

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
  		
  		pending "figure out how to activate before_save in embedded document"

  		timetable_item.project_name.should == "vistazo"
  	end
  end
end