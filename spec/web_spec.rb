begin 
  require_relative 'spec_helper'
rescue NameError
  require File.expand_path('spec_helper', __FILE__)
end

describe "Vistazo authentication" do
  
  it "should work on all pages" do
    all_pages = ['/', '/pebble_code_web_dev', '/pebble_code_web_dev/2011/week/48']
    
    all_pages.each do |page|
      get page
      last_response.status.should == 401
    end
  end
  
end

describe "Vistazo homepage" do
  before do
    authorize 'vistazo', 'vistazo'
  end
  
  after do
    MongoMapper.database.collections.each do |coll|
      coll.remove
    end
  end
  
  it "should return show welcome message" do
    get '/'
    last_response.body.should include('Welcome to the Vistazo prototype')
  end
  
  it "should show accounts" do
    Factory(:account, :name => "Fancy web shop")
    Factory(:account, :name => "Software sweets shop")
    
    get '/'
    
    last_response.body.should include('Fancy web shop')
    last_response.body.should include('Software sweets shop')
  end
  
end