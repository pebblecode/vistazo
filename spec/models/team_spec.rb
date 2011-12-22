require_relative '../spec_helper'

describe "Team model" do
  after do
    clean_db!
  end
  
  describe "has_active_users?" do
    before do
      @team = Factory(:team)
      @user = Factory(:user)
      @team.add_user_with_status(@user, :active)
    end
    
    it "should match user added" do
      Team.count.should == 1
      Team.first.has_active_user?(@user).should == true
    end
    
    it "should match user with changed uid" do
      @user.uid = "1234"
      Team.first.has_active_user?(@user).should == true
    end
    
    it "should match user with changed email" do
      @user.email = "wrong@wrong.com"
      Team.first.has_active_user?(@user).should == true
    end

    it "should match user with changed name" do
      @user.name = "nah-nah-ay"
      Team.first.has_active_user?(@user).should == true
    end
    
    it "should not match user with changed id" do
      @new_user = @user.clone # clone creates a new id
      Team.first.has_active_user?(@new_user).should == false
    end
  end
  
  describe "has_pending_users?" do
    before do
      @team = Factory(:team)
      @user = Factory(:user)
      @team.add_user_with_status(@user, :pending)
    end
    
    it "should match user added" do
      Team.count.should == 1
      Team.first.has_pending_user?(@user).should == true
    end
    
    it "should match user with changed uid" do
      @user.uid = "1234"
      Team.first.has_pending_user?(@user).should == true
    end
    
    it "should match user with changed email" do
      @user.email = "wrong@wrong.com"
      Team.first.has_pending_user?(@user).should == true
    end

    it "should match user with changed name" do
      @user.name = "nah-nah-ay"
      Team.first.has_pending_user?(@user).should == true
    end
    
    it "should not match user with changed id" do
      @new_user = @user.clone # clone creates a new id
      Team.first.has_pending_user?(@new_user).should == false
    end
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