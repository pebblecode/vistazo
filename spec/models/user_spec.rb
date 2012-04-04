require_relative '../spec_helper'

describe "User model" do
  after do
    clean_db!
  end
  
  describe "email" do
    it "should not be blank" do
      user = Factory(:user, :teams => [Factory(:team)])
      user.email = nil
      user.save.should == false
    
      user.email = ""
      user.save.should == false
    end
  
    it "should be in a valid email format" do
      user = Factory(:user, :teams => [Factory(:team)])
      user.email = "asdf"
      user.save.should == false
    
      user.email = "wrong@wrong"
      user.save.should == false
    end
  end

  describe "has_a_team?" do
    before do
      @user = Factory(:user)
      @team = Factory(:team)
    end

    it "should be false if user is not in any teams" do
      @user.has_a_team?.should == false
    end

    it "should be true if user is in a team" do
      @team.add_user(@user)
      @user.reload

      @user.has_a_team?.should == true
    end

    it "should be true if user is in multiple teams" do
      @another_team = Factory(:team)

      @team.add_user(@user)
      @another_team.add_user(@user)
      @user.reload

      @user.has_a_team?.should == true
    end
  end

  describe "remove_team" do
    before do
      @user = Factory(:user)
      @team = Factory(:team)
    end

    it "should do nothing when removing from a team a user is not in" do
      @user.remove_team(@team)
      @user.reload

      @user.teams.length.should == 0
    end

    it "should remove for 1 team" do
      @team.add_user(@user)
      @user.reload

      @user.teams.length.should == 1

      @user.remove_team(@team)
      @user.reload

      @user.teams.length.should == 0
    end

    it "should remove for more than 1 team" do
      @team.add_user(@user)
      another_team = Factory(:team)
      another_team.add_user(@user)
      @user.reload

      @user.teams.length.should == 2

      @user.remove_team(@team)
      @user.reload
      @user.teams.length.should == 1

      @user.remove_team(another_team)
      @user.reload
      @user.teams.length.should == 0
    end
  end
  
  describe "cache hash" do
    it "should work" do
      user = Factory(:user, :uid => "123", :name => "Mojojojo", :email => "mojojojo@gmail.com")
      user_id = user.id.to_s
      user.to_hash.should == {"id" => user_id, "uid" => "123", "name" => "Mojojojo", "email" => "mojojojo@gmail.com"}
    end
  end
end