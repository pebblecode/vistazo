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
    
    it "should add user to the team" do
      @team.add_user(@user).should_not == false
    end
    
    it "should add user with :pending status by default" do
      @team.add_user(@user)
      @team.has_pending_user?(@user).should == true
    end
    
    describe "with status" do
      it "should add an active user" do
        @team.add_user_with_status(@user, :active)
        @team.has_active_user?(@user).should == true
      end
      
      it "should add a pending user" do
        @team.add_user_with_status(@user, :pending)
        @team.has_pending_user?(@user).should == true
      end
      
      it "should not add unknown status users" do
        @team.add_user_with_status(@user, :not_a_valid_status).should == false
        
        @team.has_active_user?(@user).should == false
        @team.has_pending_user?(@user).should == false
      end
    end
  end
end