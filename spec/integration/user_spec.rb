require_relative '../spec_helper'

feature "User" do
  background do
    http_authorization_capybara!
    
    # Create new user
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:normal_user] }
    @team_id = Team.first.id
  end
  
  after do
    clean_db!
  end
  
  pending "can be added"
  
  pending "name can be edited"
  
  pending "name edited as empty string should show error"
  
  pending "can be deleted"

  pending "update user"
end
