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
  
  describe "cache hash" do
    user = Factory(:user, :uid => "123", :name => "Mojojojo", :email => "mojojojo@gmail.com")
    user_id = user.id.to_s
    user.to_hash.should == {:id => user_id, :uid => "123", :name => "Mojojojo", :email => "mojojojo@gmail.com"}
  end
end