# Helper rspec methods for [omniauth](http://github.com/intridea/omniauth)
module OmniauthSpecHelper
  # Omniauth settings
  OmniAuth.config.test_mode = true
  OmniAuth.config.add_mock(:google_oauth2, {
    :uid => '111965288093828509275',
    :info => {
      :email => "ttt@pebblecode.com",
      :name => 'Tu Tak Tran'
    }
  })

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
  
    def to_hash
      @data
    end
  
    def merge!(session_hash)
      @data.merge!(session_hash)
    end
  end
  
  def login!(session)
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2] }
    session['uid'] = last_request.session['uid']
  
    # Logged in user should have the same uid as login credentials
    session['uid'].should == OmniAuth.config.mock_auth[:google_oauth2]['uid']
  end

  # Based on Rack::Test::Session::follow_redirect!
  def follow_redirect_with_session_login!(session)
    unless last_response.redirect?
      raise Error.new("Last response was not a redirect. Cannot follow_redirect!")
    end

    get(last_response["Location"], {}, { "HTTP_REFERER" => last_request.url, "rack.session" => session.to_hash })
  
    # Merge last session data
    session.merge!(last_request.session)
  end

  def get_with_session_login(path, session)
    get path, nil, {"rack.session" => {"uid" => session['uid']}}
  end
end