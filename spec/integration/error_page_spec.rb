require_relative '../spec_helper'

feature "Error page" do
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  background do
    Capybara.app = VistazoApp
    http_authorization_capybara!
  end
  
  describe "Sample error (RuntimeError)" do
    scenario "should show error page" do
      visit "/error"
      
      page.should have_content("An error occurred")
      # pending "Should send email of error"
    end
  end
  
  describe "Sample error 2 (DivisionByZeroError)" do
    scenario "should show error page" do
      visit "/error2"
      
      page.should have_content("An error occurred")
      # pending "Should send email of error"
    end
  end

end
