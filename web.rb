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

############################################################################
# TODO: Figure this out
# Using the classic style for routes, because I can't get the tests running properly
# Keep a lookout on http://stackoverflow.com/questions/8356750/converting-to-modular-sinatra-app-breaks-tests
############################################################################

############################################################################
# ./routes/main.rb
############################################################################
get '/' do
  protected!
  if current_user?
    redirect "/#{current_user.account.url_slug}" if current_user.account
  end
  erb :main
end

# Vistazo weekly view - the crux of the app
get '/:account_id/:year/week/:week_num' do
  protected!
  require_account_user!(params[:account_id])
  @account = Account.find(params[:account_id])

  if @account.present?
    year = params[:year].to_i
    week_num = params[:week_num].to_i

    if ((1..NUM_WEEKS_IN_A_YEAR).include? week_num) and (year > START_YEAR)
      # Weeks start from 1
      prev_week_num = ((week_num - 1) <= 0) ? NUM_WEEKS_IN_A_YEAR : week_num - 1
      prev_week_year = ((week_num - 1) <= 0) ? year - 1 : year
      @prev_week_url = (prev_week_year > START_YEAR) ? "/#{params[:account_id]}/#{prev_week_year}/week/#{prev_week_num}" : nil

      next_week_num = ((week_num + 1) > NUM_WEEKS_IN_A_YEAR) ? 1 : week_num + 1
      next_week_year = ((week_num + 1) > NUM_WEEKS_IN_A_YEAR) ? year + 1 : year
      @next_week_url = "/#{params[:account_id]}/#{next_week_year}/week/#{next_week_num}"

      @monday_date = Date.commercial(year, week_num, MONDAY)
      @tuesday_date = Date.commercial(year, week_num, TUESDAY)
      @wednesday_date = Date.commercial(year, week_num, WEDNESDAY)
      @thursday_date = Date.commercial(year, week_num, THURSDAY)
      @friday_date = Date.commercial(year, week_num, FRIDAY)

      @projects = Project.where(:account_id => @account.id).sort(:name)
      @team_members = TeamMember.where(:account_id => @account.id).sort(:name)

      # Assume it's the right week of dates
      @team_member_projects_on_day = {}
      for tm in @team_members do
        @team_member_projects_on_day[tm] = {}

        (MONDAY..FRIDAY).each do |work_day|
          @team_member_projects_on_day[tm][work_day] = tm.team_member_projects.select { |proj| 
            (proj.date.wday == work_day) and (proj.date >= @monday_date) and (proj.date <= @friday_date)
          }
        end
      end

      erb :week
    else
      flash.next[:warning] = "Invalid week and year."
      redirect "/#{params[:account_id]}"
    end
  else
    flash.next[:warning] = "Invalid account."
    redirect '/'
  end
end

get '/css/style.css' do
  scss "sass/style".intern
end

############################################################################
# ./routes/account.rb
############################################################################

get '/:account_id' do
  protected!

  @account = Account.find(params[:account_id])

  if @account.present?
    redirect "/#{params[:account_id]}/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
  else
    flash.next[:warning] = "Invalid account."
    redirect '/'
  end
end


require_relative 'models/init'
require_relative 'helpers/init'
require_relative 'routes/init'
