require_relative '../spec_helper'

feature "Team name" do
  background do
    http_authorization_capybara!
    
    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    
  end
  
  after do
    clean_db!
  end
  
  it "Default team name, should be called \"User name's team\"" do
    visit "/"
    click_link "start-btn"
    
    default_normal_user_name = OmniAuth.config.mock_auth[:normal_user]["info"]["name"]
    page.should have_content("#{default_normal_user_name}'s team")
  end
  
  scenario "Updating to a new name" do
    team = Team.first
    team.name = "Cat's team"
    team.save
    
    visit "/"
    click_link "start-btn"
    page.should have_content("Cat's team")
    
    within_fieldset("Team name") do
      fill_in 'team_name', :with => 'Pebblez team'
      click_button 'update'
    end
    
    page.should have_content("Updated team name successfully.")
    
    within("#team-name h2") do
      page.should have_content 'Pebblez team'
    end
  end
  
  scenario "Updating to an empty name" do
    visit "/"
    click_link "start-btn"
    
    within_fieldset("Team name") do
      fill_in 'team_name', :with => ''
      click_button 'update'
    end
    
    page.should have_content("Updated team name failed. Team name was empty.")
  end

  scenario "Updating to a malicious <script> tag name should be sanitized" do
    visit "/"
    click_link "start-btn"
    
    within_fieldset("Team name") do
      fill_in 'team_name', :with => "Ha! <script type='text/javascript'>alert('hello!');</script>"
      click_button 'update'
    end

    within("#team-name h2") do
      # Note: it is sanitized with &lt; and &gt; in `page` output,
      # but is shown as as < and > in `have_content`. If the script tags 
      # are in the content of the tests, they are stripped out
      # See https://github.com/pebblecode/vistazo/issues/215
      page.should have_content("Ha! <script type='text/javascript'>alert('hello!');</script>")
    end
  end
end 