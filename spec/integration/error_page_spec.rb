require_relative '../spec_helper'

feature "Error page" do
  background do
    http_authorization_capybara!
  end
  
  def should_send_error_email_with_body(body_text)
    Pony.should_receive(:mail) { |params|
      params[:to].should == "dev@pebblecode.com"
      params[:subject].should include("Vistazo: an error occurred")
      params[:body].should include(body_text)
    }
  end
  
  describe "Sample error (RuntimeError)" do
    scenario "should show error page" do
      should_send_error_email_with_body("RuntimeError")
      visit "/error"
      page.should have_content("An error occurred")
    end
  end
  
  describe "Sample error 2 (ZeroDivisionError)" do
    scenario "should show error page" do
      should_send_error_email_with_body("ZeroDivisionError")
      visit "/error2"
      page.should have_content("An error occurred")
    end
  end

end
