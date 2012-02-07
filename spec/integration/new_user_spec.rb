require_relative '../spec_helper'

feature "New user" do
  background do
    http_authorization_capybara!
  end
  
  after do
    clean_db!
  end
  
  scenario "from new login, should have first-signon body class on first login" do
    visit "/"
    click_link "start-btn"
    page.body.should include("first-signon")
    
    visit "/"
    page.body.should_not include("first-signon")
  end
  
  it "from invite, should have first-signon body class" do
    pending
  end
end
