require_relative '../spec_helper'

describe "Project model" do
  before do
    @team = Factory(:team)
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

  describe "name" do
  	it "is required" do
  		project = Project.new(:name => "")
  		project.save.should == false
  	end
  end

  describe "team" do
  	it "references the correct team" do
  		project = Factory(:project, :team => @team)

  		project.team.should == @team
  	end
  end
end