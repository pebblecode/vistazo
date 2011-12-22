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
      
      # Should be able to see team in user
      @user.teams.include?(@team).should == true
    end
    
    it "should add user with :pending status by default" do
      @team.add_user(@user)
      @team.has_pending_user?(@user).should == true
      
      # Should be able to see team in user
      @user.teams.include?(@team).should == true
    end
    
    describe "to active users" do
      it "should contain hash of user in active_user array" do
        @team.add_user_with_status(@user, :active)
        Team.count.should == 1
        Team.first.active_users.include?(@user.to_hash).should == true
      end
    end
    
    describe "to pending users" do
      it "should contain hash of user in pending_user array" do
        @team.add_user_with_status(@user, :pending)
        Team.count.should == 1
        Team.first.pending_users.include?(@user.to_hash).should == true
      end
    end
    
    describe "with status" do
      it "should add an active user" do
        @team.add_user_with_status(@user, :active)
        @team.has_active_user?(@user).should == true
        
        # Should be able to see team in user
        @user.teams.include?(@team).should == true
      end
      
      it "should add a pending user" do
        @team.add_user_with_status(@user, :pending)
        @team.has_pending_user?(@user).should == true
        
        # Should be able to see team in user
        @user.teams.include?(@team).should == true
      end
      
      it "should not add unknown status users" do
        @team.add_user_with_status(@user, :not_a_valid_status).should == false
        
        @team.has_active_user?(@user).should == false
        @team.has_pending_user?(@user).should == false
        
        # Should *not* be able to see team in user
        @user.teams.include?(@team).should_not == true
      end
    end
  end
end