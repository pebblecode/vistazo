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
    
    it "should add user with :pending status by default" do
      @team.add_user(@user)
      @team.has_pending_user?(@user).should == true
      
      # Should NOT be able to see team in user
      @user.teams.include?(@team).should_not == true
    end
    
    describe "with status" do
      it "should add an active user" do
        @team.add_user_with_status(@user, :active)
        @team.has_active_user?(@user).should == true
        
        # Should be able to see team in user
        @user.teams.include?(@team).should == true
      end
      
      it "should only add an active user once" do
        @team.add_user_with_status(@user, :active)
        @team.active_users.select {|hash| hash["id"] == @user.id.to_s}.count.should == 1

        @team.add_user_with_status(@user, :active)
        @team.active_users.select {|hash| hash["id"] == @user.id.to_s}.count.should == 1
      end
      
      it "should update active user attributes for active_users cache" do
        @team.add_user_with_status(@user, :active)
        @team.active_users.select {|hash| hash["id"] == @user.id.to_s}.count.should == 1

        @user.name = "Javis Cocker"
        @user.email = "javis.cocker@gmail.com"
        @user.uid = "55555"
        @team.add_user_with_status(@user, :active)
        
        activate_user = @team.active_users.select {|hash| hash["id"] == @user.id.to_s}.first
        activate_user["name"].should == "Javis Cocker"
        activate_user["email"].should == "javis.cocker@gmail.com"
        activate_user["uid"].should == "55555"
      end
      
      it "should add a pending user to the team, but NOT add the user to the user teams" do
        @team.add_user_with_status(@user, :pending)
        @team.has_pending_user?(@user).should == true
        
        # Should NOT be able to see team in user
        @user.teams.include?(@team).should_not == true
      end
      
      it "should only add an pending user once" do
        @team.add_user_with_status(@user, :pending)
        @team.pending_users.select {|hash| hash["id"] == @user.id.to_s}.count.should == 1

        @team.add_user_with_status(@user, :pending)
        @team.pending_users.select {|hash| hash["id"] == @user.id.to_s}.count.should == 1
      end
      
      it "should update pending user attributes for active_users cache" do
        @team.add_user_with_status(@user, :pending)
        @team.pending_users.select {|hash| hash["id"] == @user.id.to_s}.count.should == 1

        @user.name = "Javis Cocker"
        @user.email = "javis.cocker@gmail.com"
        @user.uid = "55555"
        @team.add_user_with_status(@user, :pending)

        pending_user = @team.pending_users.select {|hash| hash["id"] == @user.id.to_s}.first
        pending_user["name"].should == "Javis Cocker"
        pending_user["email"].should == "javis.cocker@gmail.com"
        pending_user["uid"].should == "55555"
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
  
  describe "activate_user" do
    before do
      @team = Factory(:team)
      @user = Factory(:user)
      @team.add_user_with_status(@user, :pending)
    end
    
    it "should remove the user from pending users" do
      @team.activate_user(@user)
      @team.pending_users.select {|hash| hash["id"] == @user.id.to_s}.present?.should == false
    end
    
    it "should add the user to active_users" do
      @team.activate_user(@user)
      @team.active_users.select {|hash| hash["id"] == @user.id.to_s}.present?.should == true
    end
    
    it "should not add the user to active_users more than once" do
      @team.activate_user(@user)
      @team.active_users.select {|hash| hash["id"] == @user.id.to_s}.count.should == 1
      
      @team.activate_user(@user)
      @team.active_users.select {|hash| hash["id"] == @user.id.to_s}.count.should == 1
    end
    
    it "should update user attributes in active_users cache" do
      @team.activate_user(@user)
      @team.active_users.select {|hash| hash["id"] == @user.id.to_s}.count.should == 1
      
      @user.name = "Javis Cocker"
      @user.email = "javis.cocker@gmail.com"
      @user.uid = "55555"
      @team.activate_user(@user)
      
      activated_user = @team.active_users.select {|hash| hash["id"] == @user.id.to_s}.first
      activated_user["name"].should == "Javis Cocker"
      activated_user["email"].should == "javis.cocker@gmail.com"
      activated_user["uid"].should == "55555"
    end
  end
  
  describe "update_user_cache" do
    before do
      @team = Factory(:team)
      @user = Factory(:user)
    end
    
    describe "for pending user" do
      before do
        @team.add_user_with_status(@user, :pending)
      end
      
      it "should update user cache" do
        @user.name = "Javis Cocker"
        @user.email = "javis.cocker@gmail.com"
        @user.uid = "55555"
        @team.update_user_cache(@user)
      
        updated_user = @team.pending_users.select {|hash| hash["id"] == @user.id.to_s}.first
        updated_user["name"].should == "Javis Cocker"
        updated_user["email"].should == "javis.cocker@gmail.com"
        updated_user["uid"].should == "55555"
      end
      
      it "should not update active user cache" do
        @team.update_user_cache(@user)
        @team.active_users.select {|hash| hash["id"] == @user.id.to_s}.present?.should == false
      end
    end
    
    describe "for active user" do
      before do
        @team.add_user_with_status(@user, :active)
      end
      
      it "should update active user cache" do
        @user.name = "Javis Cocker"
        @user.email = "javis.cocker@gmail.com"
        @user.uid = "55555"
        @team.update_user_cache(@user)
      
        updated_user = @team.active_users.select {|hash| hash["id"] == @user.id.to_s}.first
        updated_user["name"].should == "Javis Cocker"
        updated_user["email"].should == "javis.cocker@gmail.com"
        updated_user["uid"].should == "55555"
      end
      
      it "should not update pending user cache" do
        @team.update_user_cache(@user)
        @team.pending_users.select {|hash| hash["id"] == @user.id.to_s}.present?.should == false
      end
    end
  end
end