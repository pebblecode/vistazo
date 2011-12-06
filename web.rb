# encoding utf-8

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

# Require all in lib directory
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

class VistazoApp < Sinatra::Application
  enable :sessions

  APP_CONFIG = YAML.load_file("#{root}/config/config.yml")[settings.environment.to_s]

  set :environment, ENV["RACK_ENV"] || "development"
  set :send_from_email, APP_CONFIG["send_from_email"]

  use OmniAuth::Builder do
    provider :google_oauth2,
      (ENV['GOOGLE_CLIENT_ID']||APP_CONFIG['client_id']),
      (ENV['GOOGLE_SECRET']||APP_CONFIG['google_secret']),
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
    set :session_secret, "wj-Sf/sdf_P49usi#sn132_sdnfij3"
  end

  configure :test do
    setup_mongo_connection('mongomapper://localhost:27017/vistazo-test')
  end

  ##############################################################################

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html
    
    # More methods in /helpers/*
  end
  
  MONDAY = 1
  TUESDAY = 2
  WEDNESDAY = 3
  THURSDAY = 4
  FRIDAY = 5
  START_YEAR = 2010
  NUM_WEEKS_IN_A_YEAR = 52

end

require_relative 'models/init'
require_relative 'helpers/init'
require_relative 'routes/init'
