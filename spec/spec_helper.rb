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

# Based on https://gist.github.com/375973 (from http://stackoverflow.com/a/3892401/111884)
class SessionData
  def initialize(cookies)
    @cookies = cookies
    @data = cookies['rack.session']
    if @data
      @data = @data.unpack("m*").first
      @data = Marshal.load(@data)
    else
      @data = {}
    end
  end
  
  def [](key)
    @data[key]
  end
  
  def []=(key, value)
    @data[key] = value
    session_data = Marshal.dump(@data)
    session_data = [session_data].pack("m*")
    @cookies.merge("rack.session=#{Rack::Utils.escape(session_data)}", URI.parse("//example.org//"))
    raise "session variable not set" unless @cookies['rack.session'] == session_data
  end
end

def login!(session)
  get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2] }
  session['uid'] = last_request.session['uid']
  
  # Logged in user should same uid as login credentials
  session['uid'].should == OmniAuth.config.mock_auth[:google_oauth2]['uid']
end

# Based on Rack::Test::Session::follow_redirect!
# Note: this will add 
def follow_redirect_with_session_login!(session)
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