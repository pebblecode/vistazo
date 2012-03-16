require_relative '../spec_helper'

describe "UserTimetable model" do
  before do
    @team = Factory(:team)
    @user = Factory(:user)
  end

  after do
    clean_db!
  end

  describe "new" do
    it "should have default is_visible be true" do
    	ut = UserTimetable.new(:user => @user, :team => @team)

    	ut.is_visible.should == true
    end
  end
end