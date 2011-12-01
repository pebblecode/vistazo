require 'sinatra'
require 'sinatra/flash'
require 'mongo_mapper'
require 'uri'
require 'sass'
require 'time'
require 'date'
require 'json'
require 'omniauth'
require 'omniauth-google-oauth2'

def setup_mongo_connection(mongo_url)
  url = URI(mongo_url)
  MongoMapper.connection = Mongo::Connection.new(url.host, url.port)
  MongoMapper.database = url.path.gsub(/^\//, '')
  MongoMapper.database.authenticate(url.user, url.password) if url.user && url.password
end

def get_project_css_class(str)
  get_css_class(str, "project")
end

def get_css_class(str, prefix)
  "#{prefix}-#{str.downcase.gsub(/\W/, "-")}" if str.present?
end

class VistazoApp < Sinatra::Application
  APP_CONFIG = YAML.load_file("#{root}/config/config.yml")[settings.environment.to_s]
  enable :sessions
  set :environment, ENV["RACK_ENV"] || "development"

  use OmniAuth::Builder do
    provider :google_oauth2,
      (APP_CONFIG['client_id']),
      (APP_CONFIG['google_secret']),
      {}
  end

  ##############################################################################
  # Mongo mapper settings
  ##############################################################################  
  [:production, :staging].each do |env|
    configure env do
      setup_mongo_connection(ENV['MONGOLAB_URI'])
      # what
    end
  end

  configure :development do
    setup_mongo_connection('mongomapper://localhost:27017/vistazo-development')
  end

  configure :test do
    setup_mongo_connection('mongomapper://localhost:27017/vistazo-test')
  end

  ##############################################################################

  ##############################################################################
  # Helper classes
  ##############################################################################

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html

    # From http://api.rubyonrails.org/classes/ActionView/Helpers/TextHelper.html#method-i-truncate
    def truncate(text, options = {})
      options.reverse_merge!(:length => 30)
      text.truncate(options.delete(:length), options) if text
    end

    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['vistazo', 'vistazo']
    end

  end

  ##############################################################################

  
  MONDAY = 1
  TUESDAY = 2
  WEDNESDAY = 3
  THURSDAY = 4
  FRIDAY = 5
  START_YEAR = 2010
  NUM_WEEKS_IN_A_YEAR = 52

end

require_relative "lib/fixnum"
require_relative 'models/init'
require_relative 'routes/init'
