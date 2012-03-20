require_relative '../spec_helper'

feature "New user" do
  background do
    http_authorization_capybara!
  end
  
  after do
    clean_db!
  end
  
  describe "from new login" do
    scenario "has first-signon body class on first login" do
      visit "/"
      click_link "start-btn"
      page.body.should include("first-signon")
      
      visit "/"
      page.body.should_not include("first-signon")
    end
    
    scenario "is in team" do
      visit "/"
      click_link "start-btn"

      # Should have user in team
      pending "Check user"
    end
  end
end
