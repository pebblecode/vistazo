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
  
  describe "status" do
    
  end
end