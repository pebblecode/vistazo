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
require 'pony'

# Require all in lib directory
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

class VistazoApp < Sinatra::Application

  APP_CONFIG = YAML.load_file("#{root}/config/config.yml")[settings.environment.to_s]

  set :environment, ENV["RACK_ENV"] || "development"
  set :send_from_email, APP_CONFIG["send_from_email"]

  enable :sessions
  
  use OmniAuth::Builder do
    provider :google_oauth2,
      (ENV['GOOGLE_CLIENT_ID']||APP_CONFIG['client_id']),
      (ENV['GOOGLE_SECRET']||APP_CONFIG['google_secret']),
      {}
  end

  ##############################################################################
  # Configurations for different environments
  ##############################################################################
  [:production, :staging].each do |env|
    configure env do
      setup_mongo_connection(ENV['MONGOLAB_URI'])
    end
  end

  configure :staging do
    enable :logging
  end

  configure :development do
    setup_mongo_connection('mongomapper://localhost:27017/vistazo-development')
    set :session_secret, "wj-Sf/sdf_P49usi#sn132_sdnfij3"
    
    enable :logging
  end

  configure :test do
    setup_mongo_connection('mongomapper://localhost:27017/vistazo-test')
  end

  ##############################################################################

end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
  
  # More methods in /helpers/*
end

# Constants

MONDAY = 1
TUESDAY = 2
WEDNESDAY = 3
THURSDAY = 4
FRIDAY = 5
START_YEAR = 2010
NUM_WEEKS_IN_A_YEAR = 52

require_relative 'models/init'
require_relative 'helpers/init'

##############################################################################
# Routes/Controllers
# To be moved once I figure out how to (http://stackoverflow.com/q/8356750/111884)
##############################################################################

get "/error" do
  raise "ERRRRORRRRR!!!"
end

# ----------------------------------------------------------------------------
# Authentication
# NOTE: This must be loaded first
# ----------------------------------------------------------------------------

get '/auth/:provider/callback' do
  hash = request.env['omniauth.auth'].to_hash if request.env['omniauth.auth'].present?
  
  if not(hash.present?)
    flash[:warning] = "Invalid login: No details."
  elsif not(hash["uid"].present?)
    flash[:warning] = "Invalid login: No user id."
  elsif not(hash["info"]["email"].present?)
    flash[:warning] = "Invalid login: No email."
  else
    @user = User.find_by_uid(hash["uid"])
    unless @user.present?
      @user = User.find_by_email(hash["info"]["email"])

      if @user.present? # Present if invited and following registration link
        @user.uid = hash["uid"]
        @user.name = hash["info"]["name"]
        
        @user.save
        
        if @user.valid?
          flash[:success] = "Welcome to Vistazo! You've successfully registered."
        else
          flash[:warning] = "Could not register user."
          puts @user.errors
          @user = nil
          redirect '/'
        end
      else
        @user = User.create(
          :uid   => hash["uid"],
          :name  => hash["info"]["name"],
          :email => hash["info"]["email"]
        )
        if @user.valid?
          @account = create_account

          # Add the user as the first team member
          @account.team_members << TeamMember.create(:name => @user.name)

          flash[:success] = "Welcome to Vistazo! We're ready for you to add projects for yourself."
        else
          flash[:warning] = "Could not retrieve user."
          
          puts "Error creating user:"
          @user.errors.each { |e| puts "#{e}: #{@user.errors[e]}" }
          
          @user = nil
          redirect '/'
        end
      end
    end
  
    session['uid'] = @user.uid
  end
  
  redirect '/'
end

get '/auth/failure' do
  flash[:warning] = "To access vistazo, you need to login with your Google account."
  redirect "/"
end
get '/logout' do
  flash[:success] = "Logged out successfully"
  log_out
end

def create_account
  @user.account = Account.create(:name => "#{@user.name}'s schedule")
  @user.save
  return @user.account
end

# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------

get '/' do
  protected!
  if current_user?
    redirect "/#{current_user.account.url_slug}" if current_user.account
  end
  erb :homepage, :layout => false
end

# Vistazo weekly view - the crux of the app
get '/:account_id/:year/week/:week_num' do
  protected!
  require_account_user!(params[:account_id])
  @account = Account.find(params[:account_id])
  @active_users = @account.active_users
  @pending_users = @account.pending_users
  
  @show_users = true
  
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

# ----------------------------------------------------------------------------
# Account
# ----------------------------------------------------------------------------
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

post '/:account_id/new-user' do
  puts "New user: #{params}"
  email = params[:new_user_email]
  
  @account = Account.find(params[:account_id])
  if @account.present?
    @user = User.new(:email => email, :account => @account)
    if @user.save
      
      # Send registration email
      begin
        send_registration_email_to @user.email
        flash[:success] = "Invitation email has been sent to #{@user.email}"
      rescue Exception => e
        puts "Email error: #{e}"
        flash[:warning] = "It looks like something went wrong while attempting to send your email. Please try again another time. Error: #{e}"
      end
    else
      flash[:warning] = "Email is not valid"
    end
  else
    flash[:warning] = "Account is not valid"
  end
  
  redirect '/'
end

get '/:account_id/new-user/register' do
  protected!
  
  @account = Account.find(params[:account_id])
  if @account.present?
    erb :new_user_registration
  else
    flash[:warning] = "Invalid account"
    redirect '/'
  end
end

get '/:account_id/new-user/:user_id/resend' do
  protected!

  @account = Account.find(params[:account_id])
  if @account.present?
    begin
      @user = User.find(params[:user_id])
      if @user.present?
        send_registration_email_to @user.email
        flash[:success] = "Invitation email has been resent to #{@user.email}"
      else
        flash[:warning] = "Invalid user to resend email to."
      end
    rescue Exception => e
      puts "Email error: #{e}"
      flash[:warning] = "It looks like something went wrong while attempting to send your email. Please try again another time. Error: #{e}"
    end
  else
    flash[:warning] = "Invalid account"
  end
  
  redirect back
end

private


def send_registration_email_to(send_to_email)
  @signup_link = "#{APP_CONFIG['base_url']}/#{params[:account_id]}/new-user/register"
  
  send_from_email = settings.send_from_email
  subject = "You are invited to Vistazo"
  
  email_params = {
    :email_service_address => "smtp.sendgrid.net",
    :email_service_username => ENV['SENDGRID_USERNAME'] || APP_CONFIG['email_service_username'],
    :email_service_password => ENV['SENDGRID_PASSWORD'] || APP_CONFIG['email_service_password'],
    :email_sevice_domain => ENV['SENDGRID_DOMAIN'] || APP_CONFIG['email_service_domain']
  }
  
  if ENV['RACK_ENV'] == "development"
    puts "DEVELOPMENT MODE: email not actually sent, but this is what it'd look like..."
    puts "send_from_email: #{send_from_email}"
    puts "send_to_email: #{send_to_email}"
    puts "params: #{email_params}"
    puts "subject: #{subject}"
            
    puts erb(:new_user_email, :layout => false)
  elsif (ENV['RACK_ENV'] != "test")
    if ENV['RACK_ENV'] == "staging"
      puts "STAGING MODE: this email should be sent:"
      puts "send_from_email: #{send_from_email}"
      puts "send_to_email: #{send_to_email}"
      puts "params: #{email_params}"
      puts "subject: #{subject}"
      
      puts erb(:new_user_email, :layout => false)
    end
  
    puts erb(:new_user_email, :layout => false)
    
    send_email(send_from_email, send_to_email, subject, :new_user_email, email_params)
  end
end

# ----------------------------------------------------------------------------
# Project
# ----------------------------------------------------------------------------

post '/:account_id/team-member-project/add' do
  protected!

  account = Account.find(params[:account_id])
  team_member = TeamMember.find(params[:team_member_id])
  date = Date.parse(params[:date])

  puts "Add team member project: #{params}"

  if params[:new_project].present?
    project_name = params[:new_project_name]
  
    if project_name.present?
      if account.present?
        project = Project.create(:name => project_name, :account_id => account.id)
        team_member.add_project_on_date(project, date)
    
        flash[:success] = "Successfully added '<em>#{project.name}</em>' project for #{team_member.name} on #{date}."
      else
        flash[:warning] = "Invalid account."
      end
    else
      flash[:warning] = "Please specify a project name."
    end
  else
    project = Project.find(params[:project_id])
    if (team_member.present? and project.present? and date.present?)
      team_member.add_project_on_date(project, date)
    
      flash[:success] = "Successfully added '<em>#{project.name}</em>' project for #{team_member.name} on #{date}."
    else
      flash[:warning] = "Something went wrong when adding a team member project. Please refresh and try again later."
    end
  end

  redirect back
end

post '/team-member-project/:tm_project_id/update.json' do
  protected!

  from_team_member = TeamMember.find(params[:from_team_member_id])
  to_team_member = TeamMember.find(params[:to_team_member_id])
  team_member_project = from_team_member.team_member_projects.find(params[:tm_project_id]) if from_team_member
  to_date = Date.parse(params[:to_date])

  puts "Update team member project params: #{params}"

  output = ""
  if (from_team_member.present? and to_team_member.present? and team_member_project.present? and to_date.present?)
    successful_move = from_team_member.move_project(team_member_project, to_team_member, to_date)
  
    if successful_move
      status 200
      output = { :message => "Successfully moved '<em>#{team_member_project.project_name}</em>' project to #{to_team_member.name} on #{to_date}." }
    else
      status 500
      output = { :message => "Something went wrong with saving the changes when updating team member project. Please refresh and try again later." }
    end
  else
    status 400
    output = { :message => "Something went wrong with the input when updating team member project. Please refresh and try again later." }
  end

  content_type :json 
  output.to_json
end

post '/team-member/:team_member_id/project/:tm_project_id/delete' do
  protected!

  team_member = TeamMember.find(params[:team_member_id])

  if team_member.present?
    did_delete = team_member.team_member_projects.reject! { |proj| proj.id.to_s == params[:tm_project_id] }
    team_member.save

    if did_delete
      flash[:success] = "Successfully deleted team member project for #{team_member.name}."
    else
      flash[:warning] = "Something went wrong when trying to delete a team member project for #{team_member.name}. Please try again later."
    end
  else
    flash[:warning] = "Something went wrong when trying to delete a team member project. Please refresh and try again later."
  end

  redirect back
end

# ----------------------------------------------------------------------------
# Team member
# ----------------------------------------------------------------------------

post '/:account_id/team-member/add' do
  protected!

  account = Account.find(params[:account_id])

  puts "Add team member: #{params}"

  if account.present?
    team_member_name = params[:new_team_member_name]
  
    if team_member_name.present?
      team_member = TeamMember.create(:name => team_member_name, :account_id => account.id)
    
      flash[:success] = "Successfully added '<em>#{team_member.name}</em>'."
    else
      flash[:warning] = "Please specify a team member name."
    end
    
  else
    flash[:warning] = "Invalid account"
  end

  redirect back
end

# ----------------------------------------------------------------------------
# Admin testing
# ----------------------------------------------------------------------------

post '/reset' do
  protected!

  # Delete everything
  TeamMember.delete_all()
  Project.delete_all()
  ColourSetting.delete_all()
  Account.delete_all()
  User.delete_all()

  flash[:success] = "Successfully cleared out the database and added seed data. Enjoy!"
  redirect '/'
end

# ----------------------------------------------------------------------------
# Error handling
# ----------------------------------------------------------------------------

error do
  'Sorry, there was an error with Vistazo: ' + env['sinatra.error'].name
end

error RuntimeError do
  'Had a RuntimeError ' + env['sinatra.error'].message
end
