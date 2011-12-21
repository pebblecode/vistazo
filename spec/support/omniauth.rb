# Helper rspec methods for [omniauth](http://github.com/intridea/omniauth)
module OmniauthSpecHelper
  # Omniauth settings
  OmniAuth.config.test_mode = true
  # Set default provider to be "google_oauth2"
  OmniAuth.config.mock_auth[:default]["provider"] = "google_oauth2"
  OmniAuth.config.mock_auth[:normal_user] = OmniAuth.config.mock_auth[:default].merge({
    "uid" => '113782480773906051024',
    "info" => {
      "email" => "vistazo.test@gmail.com",
      "name" => 'Vistazo Test'
    }
  })
  OmniAuth.config.mock_auth[:super_admin] = OmniAuth.config.mock_auth[:default].merge({
    "uid" => '111965288093828509275',
    "info" => {
      "email" => "ttt@pebblecode.com",
      "name" => 'Tu Tak Tran'
    }
  })
  
  # Default for google_oauth2 is :normal_user - used in capybara integration tests
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth.config.mock_auth[:normal_user]
  
  # SessionData idea based on http://gist.github.com/375973 (from http://stackoverflow.com/a/3892401/111884)
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
  
  def init_omniauth_session
    SessionData.new(rack_test_session.instance_variable_get(:@rack_mock_session).cookie_jar)
  end
  
  def login_normal_user_with_session!(session)
    login!(:normal_user, session)
  end
  
  def login_super_admin_with_session!(session)
    login!(:super_admin, session)
  end
  
  def login!(omniauth_mock_user_key, session)
    get '/auth/google_oauth2/callback', nil, { "omniauth.auth" => OmniAuth.config.mock_auth[omniauth_mock_user_key] }
    
    session.merge!(last_request.session)
    # Logged in user should have the same uid as login credentials
    session['uid'].should == OmniAuth.config.mock_auth[omniauth_mock_user_key]['uid']
    
    # Should redirect to homepage
    follow_redirect_with_session_login!(session)
    last_request.path.should == "/"
    
    # Find team by uid - should be first team in team list
    team = User.find_by_uid(session['uid']).teams.first
    
    # Should redirect to team page
    follow_redirect_with_session_login!(@session)
    last_request.path.should == "/#{team.id}"
    
    # Should redirect to current week
    follow_redirect_with_session_login!(@session)
    last_request.path.should == "/#{team.id}/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
  end
  
  def logout_session!(session)
    get_with_session_login! '/logout', session
    
    last_request.session['uid'].should == nil
    last_request.session[:flash][:success] == "Logged out successfully"
    
    follow_redirect_with_session_login!(session)
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

  # GET using session data. Does **not** merge session data after get request.
  def get_with_session_login(path, session)
    get path, nil, {"rack.session" => {"uid" => session['uid']}}
  end
  
  # GET using session data. **Merges** session data after get request.
  def get_with_session_login!(path, session)
    get_with_session_login(path, session)
    session.merge!(last_request.session)
  end
  
  # POST using session data. Does **not** merge session data after POST request.
  def post_params(path, params, session)
    post path, params, {"rack.session" => {"uid" => session['uid']}}
  end
  
  # POST using session data. **Merges** session data after POST request.
  def post_params!(path, params, session)
    post_params(path, params, session)
    session.merge!(last_request.session)
  end

  
  def user_from_session(session)
    session['uid'].nil? ? nil: User.find_by_uid(session['uid'])
  end
  
  def create_normal_user(session)
    # Create a new login for normal user will create a new user and team
    login_normal_user_with_session!(session)
    logout_session!(session)
  end
end