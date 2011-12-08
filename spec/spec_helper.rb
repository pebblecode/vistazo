# spec_helper.rb
ENV['RACK_ENV'] = 'test'

# Include web.rb file
require_relative '../web'
# Include factories.rb file
require_relative '../test/factories.rb'

require 'rspec'
require 'rack/test'
require 'factory_girl'
require 'ruby-debug'

# Include Rack::Test in all rspec tests
RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.mock_with :rspec
end

# Omniauth settings
OmniAuth.config.test_mode = true
OmniAuth.config.add_mock(:google_oauth2, {
  :uid => '111965288093828509275',
  :info => {
    :email => "ttt@pebblecode.com",
    :name => 'Tu Tak Tran'
  }
})

# Helper methods

def http_authorization!
  authorize 'vistazo', 'vistazo'
end

# TODO: Get this working. See http://stackoverflow.com/q/8419286/111884
def login!
  # Disable sessions, and set manually
  # app.send(:set, :sessions, false)
  
  get '/auth/google_oauth2/callback', nil, {"omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2] }
  # last_request.session => {"uid"=>"111965288093828509275", :flash=>{:success=>"Welcome to Vistazo! We're ready for you to add projects for yourself."}}
  # last_response.body => ""
  
  follow_redirect!
  # last_request.session => {:flash=>{}}
  # last_response.body => Html for the homepage, which is what I want  
  # HERE lies the problem!
  
end

# Based on Rack::Test::Session::follow_redirect!
def follow_redirect_with_session_login!
  unless last_response.redirect?
    raise Error.new("Last response was not a redirect. Cannot follow_redirect!")
  end

  get(last_response["Location"], {}, { "HTTP_REFERER" => last_request.url, "rack.session" => {"uid" => session['uid']} })
end

def get_with_session_login(path)
  get path, nil, {"rack.session" => {"uid" => session['uid']}}
end

def clean_db!
  MongoMapper.database.collections.each do |coll|
    coll.remove
  end
end