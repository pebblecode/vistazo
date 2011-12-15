require_relative '../spec_helper'

# Define application for all spec files
def app
  Sinatra::Application
end

describe "send_email.rb:" do
  before do
    Pony.stub!(:deliver)
  end
  
  describe "Valid parameters" do
    it "should send an email" do
      params = {
        :address => "smtp.gmail.com",
        :domain => "vistazoapp.com",
        :port => '587',
        :enable_starttls_auto => true,
        :user_name => "user",
        :password => "pass"
      }
      
      default_params = {
        :authentication => :plain
      }
      
      Pony.should_receive(:build_mail).with(hash_including({
        :from => "bob@gmail.com",
        :to => "dev@pebblecode.com",
        :subject => "Hello",
        :body => "Allo allo Bob!",
        :via_options => params.merge(default_params)
      }))
      send_email("bob@gmail.com", 
                 "dev@pebblecode.com", 
                 "Hello", 
                 "Allo allo Bob!", 
                 params)
    end
  end
  
  describe "Invalid parameters" do
    pending "(don't check parameters at the moment)"
  end
  
  describe "Default parameters" do
    it "should contain :port and :authentication" do
      Pony.should_receive(:build_mail).with(hash_including({
        :via_options => {
          :port           => "25",
          :authentication => :plain
        }
      }))
      send_email("", 
                 "", 
                 "", 
                 "", 
                 {})
    end
  end
  
end