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
    
    it "should be add team to user teams" do
      @team.add_user(@user)
      @user.team_ids.include?(@team.id).should == true
    end
  end
end