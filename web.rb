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
require "newrelic_rpm"
require 'rack-force_domain'

# Require all in lib directory
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

set :version_string, "0.7.1 release"

class VistazoApp < Sinatra::Application
  
  APP_CONFIG = YAML.load_file("#{root}/config/config.yml")[settings.environment.to_s]
  
  set :environment, ENV["RACK_ENV"] || "development"
  set :send_from_email, APP_CONFIG["send_from_email"]
  
  enable :sessions
  
  # Redirect all urls on production (http://github.com/cwninja/rack-force_domain)
  use Rack::ForceDomain, ENV["DOMAIN"]  
  
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
SATURDAY = 6
SUNDAY = 7
START_YEAR = 2010
NUM_WEEKS_IN_A_YEAR = 52

HTTP_STATUS_OK = 200
HTTP_STATUS_BAD_REQUEST = 400
HTTP_STATUS_INTERNAL_SERVER_ERROR = 500

require_relative 'models/init'
require_relative 'helpers/init'

##############################################################################
# Routes/Controllers
# To be moved once I figure out how to (http://stackoverflow.com/q/8356750/111884)
##############################################################################

get "/error" do
  raise "Sample error"
end

get "/error2" do
  1/0
end


# ----------------------------------------------------------------------------
# Admin testing
# ----------------------------------------------------------------------------

post '/reset' do
  protected!

  # Delete everything except system collections
  MongoMapper.database.collections.each do |coll|
    unless coll.name.match /^system\..+/
      logger.warn "Deleting #{coll.name}"
      coll.drop
    end
  end

  flash[:success] = "Successfully cleared out the database. All nice and clean now."
  redirect '/'
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
          if @user.teams.present?
            @user.teams.each {|t| t.update_user_cache(@user)}
          end
          flash[:success] = "Welcome to Vistazo! You've successfully registered."
        else
          flash[:warning] = "Could not register user."
          logger.warn @user.errors
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
          @team = Team.create_for_user(@user)
          
          # Add the user as the first team member
          @team.team_members << TeamMember.create(:name => @user.name)
          if @team.save
            flash[:success] = "Welcome to Vistazo! We're ready for you to add projects for yourself."
          else
            flash[:warning] = "Something wrong happened. Please try again another time."
          end
        else
          flash[:warning] = "Could not retrieve user."
          
          logger.warn "Error creating user:"
          @user.errors.each { |e| logger.warn "#{e}: #{@user.errors[e]}" }
          
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
  redirect '/'
end
get '/logout' do
  flash[:success] = "Logged out successfully"
  log_out
end

# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------

get '/' do
  protected!
  
  if current_user?
    logger.info "Homepage with user: #{current_user.name} with teams: #{current_user.teams}"
    redirect "/#{current_user.teams.first.url_slug}" if current_user.teams.present?
  end
  erb :homepage, :layout => false
end

# Vistazo weekly view - the crux of the app
get '/:team_id/:year/week/:week_num' do
  protected!
  require_team_user!(params[:team_id])
  
  if current_user.is_new
    @first_signon = current_user.is_new
    current_user.is_new = false
    current_user.save
  end
    
  @team = Team.find(params[:team_id])
  @active_users = @team.active_users
  @pending_users = @team.pending_users
  
  @show_users = true
  
  if @team.present?
    year = params[:year].to_i
    week_num = params[:week_num].to_i

    if ((1..NUM_WEEKS_IN_A_YEAR).include? week_num) and (year > START_YEAR)
      # Weeks start from 1
      prev_week_num = ((week_num - 1) <= 0) ? NUM_WEEKS_IN_A_YEAR : week_num - 1
      prev_week_year = ((week_num - 1) <= 0) ? year - 1 : year
      @prev_week_url = (prev_week_year > START_YEAR) ? "/#{params[:team_id]}/#{prev_week_year}/week/#{prev_week_num}" : nil

      next_week_num = ((week_num + 1) > NUM_WEEKS_IN_A_YEAR) ? 1 : week_num + 1
      next_week_year = ((week_num + 1) > NUM_WEEKS_IN_A_YEAR) ? year + 1 : year
      @next_week_url = "/#{params[:team_id]}/#{next_week_year}/week/#{next_week_num}"

      @monday_date = Date.commercial(year, week_num, MONDAY)
      @tuesday_date = Date.commercial(year, week_num, TUESDAY)
      @wednesday_date = Date.commercial(year, week_num, WEDNESDAY)
      @thursday_date = Date.commercial(year, week_num, THURSDAY)
      @friday_date = Date.commercial(year, week_num, FRIDAY)
      @saturday_date = Date.commercial(year, week_num, SATURDAY)
      @sunday_date = Date.commercial(year, week_num, SUNDAY)

      @projects = Project.where(:team_id => @team.id).sort(:name)
      @team_members = TeamMember.where(:team_id => @team.id).sort(:name)

      # Assume it's the right week of dates
      @timetable_items_on_day = {}
      for tm in @team_members do
        @timetable_items_on_day[tm] = {}

        (MONDAY..SUNDAY).each do |work_day|
          @timetable_items_on_day[tm][work_day] = tm.timetable_items.select { |proj|
            (proj.date.cwday == work_day) and (proj.date >= @monday_date) and (proj.date <= @sunday_date)
          }
        end
      end

      erb :week
    else
      flash.next[:warning] = "Invalid week and year."
      redirect "/#{params[:team_id]}"
    end
  else
    flash.next[:warning] = "Invalid team."
    redirect back
  end
end

get '/css/style.css' do
  scss "sass/style".intern
end

# ----------------------------------------------------------------------------
# Team
# ----------------------------------------------------------------------------

post '/team/new' do
  @team = Team.create_for_user(current_user)
  
  # Add the user as the first team member
  @team.team_members << TeamMember.create(:name => current_user.name)
  @team.name = params[:new_team_name]
  if @team.save
    flash[:success] = "Successfully created team."
  else
    flash[:warning] = "Create team failed. Team name empty."
  end
  
  # Redirect to new team
  redirect "/#{@team.id}"
end

get '/:team_id' do
  protected!
  
  @team = Team.find(params[:team_id])
  logger.info "Team page (#{@team}) with user: #{current_user}"
  if @team.present?
    redirect "/#{params[:team_id]}/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
  else
    flash.next[:warning] = "Invalid team."
    redirect '/'
  end
end

post '/:team_id/user/new' do
  logger.info "New user: #{params}"
  email = params[:new_user_email]
  
  @team = Team.find(params[:team_id])
  if @team.present?
    @user = User.find_by_email(email)
    if @user.present?
      if @team.has_pending_user?(@user)
        flash[:warning] = "User has already been sent an invitation email. To resend, open the user settings and click on the resend button next to their email address."
      elsif @team.has_active_user?(@user)
        flash[:warning] = "User is already registered to this team."
      else
        @team.add_user(@user)
        send_registration_email_for_params(@user, params)
        
        flash[:success] = "Invitation email has been sent"
      end
    else
      @user = User.new(:email => email)
      if @user.save
        @team.add_user(@user)
        send_registration_email_for_params(@user, params)
      else
        flash[:warning] = "Email is not valid"
      end
    end
  else
    flash[:warning] = "Team is not valid"
  end
  
  redirect back
end

get '/:team_id/user/:user_id/register' do
  protected!
  
  @team = Team.find(params[:team_id])
  if @team.present?
    @user = User.find(params[:user_id])
    if @user.present?
      @activation_link = "#{APP_CONFIG['base_url']}/#{@team.id}/user/#{@user.id}/activate"
      erb :new_user_registration, :layout => false
    else
      flash[:warning] = "Invalid user"
      redirect '/'
    end
  else
    flash[:warning] = "Invalid team"
    redirect '/'
  end
end

get '/:team_id/user/:user_id/activate' do
  protected!
  
  @team = Team.find(params[:team_id])
  if @team.present?
    @user = User.find(params[:user_id])
    if @user.present?
      @team.activate_user(@user)
      
      # Login
      redirect "/auth/google_oauth2/"
    else
      flash[:warning] = "Invalid user"
      redirect '/'
    end
  else
    flash[:warning] = "Invalid team"
    redirect '/'
  end
end

post '/:team_id/user/:user_id/resend' do
  protected!
  
  @team = Team.find(params[:team_id])
  if @team.present?
    @user = User.find(params[:user_id])
    send_registration_email_for_params(@user, params)
  else
    flash[:warning] = "Invalid team"
  end
  
  redirect back
end

def send_registration_email_for_params(user, params)
  begin
    if user.present?
      send_registration_email_to user
      flash[:success] = "Invitation email has been sent to #{user.email}"
    else
      flash[:warning] = "Invalid user to send email to."
    end
  rescue Exception => e
    logger.warn "Email error: #{e}"
    flash[:warning] = "It looks like something went wrong while attempting to send your email. Please try again another time. Error: #{e}"
  end
end

post '/:team_id/update' do
  protected!
  require_team_user!(params[:team_id])
    
  @team = Team.find(params[:team_id])
  if @team.present?
    team_name = params[:team_name]
    if team_name.present?
      @team.name = team_name
      @team.save
      
      flash[:success] = "Updated team name successfully."
    else
      flash[:warning] = "Updated team name failed. Team name was empty."
    end
  end
  
  redirect back
end

def send_registration_email_to(user)
  @signup_link = "#{APP_CONFIG['base_url']}/#{params[:team_id]}/user/#{user.id}/register"
  
  send_from_email = settings.send_from_email
  subject = "You are invited to Vistazo"
  
  email_params = {
    :address => "smtp.sendgrid.net",
    :user_name => ENV['SENDGRID_USERNAME'] || APP_CONFIG['email_service_username'],
    :password => ENV['SENDGRID_PASSWORD'] || APP_CONFIG['email_service_password'],
    :domain => APP_CONFIG['email_service_domain'],
    :port => '587',
    :authentication => :plain,
    :enable_starttls_auto => true
  }
  
  if ENV['RACK_ENV'] == "development"
    logger.info "DEVELOPMENT MODE: email not actually sent, but this is what it'd look like..."
    logger.info "send_from_email: #{send_from_email}"
    logger.info "send_to_email: #{user.email}"
    logger.info "params: #{email_params}"
    logger.info "subject: #{subject}"
            
    logger.info erb(:new_user_email, :layout => false)
  else
    if ENV['RACK_ENV'] == "staging"
      logger.info "STAGING MODE: this email should be sent:"
      logger.info "send_from_email: #{send_from_email}"
      logger.info "send_to_email: #{user.email}"
      logger.info "params: #{email_params}"
      logger.info "subject: #{subject}"
      
      logger.info erb(:new_user_email, :layout => false)
    end
    
    send_email(send_from_email, user.email, subject, erb(:new_user_email, :layout => false), email_params)
  end
end

# ----------------------------------------------------------------------------
# Project
# ----------------------------------------------------------------------------


############################################
# Add team member project
############################################

post '/:team_id/team-member-project/add' do
  protected!
  require_team_user!(params[:team_id])
  
  team = Team.find(params[:team_id])
  team_member = TeamMember.find(params[:team_member_id])
  date = Date.parse(params[:date])

  logger.info "Add team member project: #{params}"

  if params[:new_project].present?
    project_name = params[:new_project_name]
  
    if project_name.present?
      if team.present?
        project = Project.create(:name => project_name, :team_id => team.id)
        team_member.add_project_on_date(project, date)
    
        flash[:success] = "Successfully added '<em>#{project.name}</em>' project for #{team_member.name} on #{date}."
      else
        flash[:warning] = "Invalid team."
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

post '/:team_id/team-member/:team_member_id/project/add.?:format?' do
  protected!
  require_team_user!(params[:team_id])
  
  team = Team.find(params[:team_id])
  team_member = TeamMember.find(params[:team_member_id])
  date = Date.parse(params[:date])

  logger.info "Add team member project: #{params}"

  if params[:new_project].present?
    project_name = params[:new_project_name]
  
    if project_name.present?
      if team.present?
        project = Project.create(:name => project_name, :team_id => team.id)
        team_member_project = team_member.add_project_on_date(project, date)
        
        outputMsg = "Successfully added '<em>#{project.name}</em>' project for #{team_member.name} on #{date}."
        if params[:format] == "json"
          status HTTP_STATUS_OK
          output = { :message => outputMsg, :team_member_project_id => team_member_project.id }
        else
          flash[:success] = outputMsg
        end
      else
        outputMsg = "Invalid team."
        if params[:format] == "json"
          status = HTTP_STATUS_BAD_REQUEST
          output = { :message => outputMsg }
        else
          flash[:warning] = outputMsg
        end
      end
    else
      outputMsg = "Please specify a project name."
      if params[:format] == "json"
        status = HTTP_STATUS_BAD_REQUEST
        output = { :message => outputMsg }
      else
        flash[:warning] = outputMsg
      end
    end
  else
    project = Project.find(params[:project_id])
    if (team_member.present? and project.present? and date.present?)
      team_member_project = team_member.add_project_on_date(project, date)
      
      outputMsg = "Successfully added '<em>#{project.name}</em>' project for #{team_member.name} on #{date}."
      if params[:format] == "json"
        status HTTP_STATUS_OK
        output = { :message => outputMsg, :team_member_project_id => team_member_project.id }
      else
        flash[:success] = outputMsg
      end
    else
      logger.warn "Add existing team member project error: team_member: #{team_member}, project: #{project}, date: #{date}"
      outputMsg = "Something went wrong when adding a team member project. Please refresh and try again later."
      if params[:format] == "json"
        status = HTTP_STATUS_BAD_REQUEST
        output = { :message => outputMsg }
      else
        flash[:warning] = outputMsg
      end
    end
  end

  if params[:format] == "json"
    content_type :json
    output.to_json
  else
    redirect back
  end
end


############################################
# Update team member project
############################################

post '/:team_id/team-member-project/:tm_project_id/update.json' do
  protected!
  require_team_user!(params[:team_id])
  
  output = ""
  current_user_team = Team.find(params[:team_id])
  if current_user_team.present?
    from_team_member = TeamMember.find(params[:from_team_member_id])
    to_team_member = TeamMember.find(params[:to_team_member_id])
    timetable_item = from_team_member.timetable_items.find(params[:tm_project_id]) if from_team_member
    to_date = Date.parse(params[:to_date]) if params[:to_date]
    
    logger.info "Update team member project params: #{params}"
    
    
    if (from_team_member.present? and to_team_member.present? and timetable_item.present? and to_date.present?)
      if ((from_team_member.team == current_user_team) and (to_team_member.team == current_user_team))
        successful_move = from_team_member.move_project(timetable_item, to_team_member, to_date)
  
        if successful_move
          status HTTP_STATUS_OK
          output = { :message => "Successfully moved '<em>#{timetable_item.project_name}</em>' project to #{to_team_member.name} on #{to_date}." }
        else
          status HTTP_STATUS_INTERNAL_SERVER_ERROR
          output = { :message => "Something went wrong with saving the changes when updating team member project. Please refresh and try again later." }
        end
      else
        status HTTP_STATUS_BAD_REQUEST
        output = { :message => "Invalid team." }
      end
    else
      status HTTP_STATUS_BAD_REQUEST
      output = { :message => "Something went wrong with the input when updating team member project. Please refresh and try again later." }
    end
  else
    status HTTP_STATUS_BAD_REQUEST
    output = { :message => "Invalid team." }
  end
  
  content_type :json 
  output.to_json
end


############################################
# Delete team member project
############################################

post '/team-member/:team_member_id/project/:tm_project_id/delete' do
  protected!

  team_member = TeamMember.find(params[:team_member_id])
  
  if team_member.present?
    did_delete = team_member.timetable_items.reject! { |proj| proj.id.to_s == params[:tm_project_id] }
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

post '/team-member/:team_member_id/project/:tm_project_id/delete.json' do
  protected!

  team_member = TeamMember.find(params[:team_member_id])
  output = ""
  if team_member.present?
    did_delete = team_member.timetable_items.reject! { |proj| proj.id.to_s == params[:tm_project_id] }
    team_member.save

    if did_delete
      status HTTP_STATUS_OK
      output = { :message => "Successfully deleted team member project for #{team_member.name}." }
    else
      status HTTP_STATUS_INTERNAL_SERVER_ERROR
      output = { :message => "Something went wrong when trying to delete a team member project for #{team_member.name}. Please try again later." }
    end
  else
    status HTTP_STATUS_BAD_REQUEST
    output = { :message => "Something went wrong when trying to delete a team member project. Please refresh and try again later." }
  end

  content_type :json 
  output.to_json
end


############################################
# Delete project
############################################

post "/:team_id/project/:project_id/delete" do
  protected!
  require_team_user!(params[:team_id])
  
  project = Project.find(params[:project_id])
  if project.present?
    if project.team_id.to_s == params[:team_id]
      logger.info "Deleting project #{project.id} and all team member timetable items"
      project_name = project.name
      TeamMember.all.each do |tm|
        tm.timetable_items.delete_if { |ti| ti.project_id == project.id }
        tm.save
      end
      Project.delete project.id
      flash[:success] = "Successfully deleted project '#{project_name}'."
    else
      logger.warn "Deleting project failed, not in right team. Project: #{project.team_id}. Got #{params[:team_id]}"
      flash[:warning] = "Invalid team."
    end
  else
    logger.warn "Deleting project failed, project not valid: #{project}"
    flash[:warning] = "Invalid project."
  end
  
  redirect back
end

# ----------------------------------------------------------------------------
# Team member
# ----------------------------------------------------------------------------

get '/:team_id/team-members.json' do
  protected!
  require_team_user!(params[:team_id])

  logger.info("Team members");
  @team = Team.find(params[:team_id])
  if @team.present?
    @team_members = TeamMember.where(:team_id => @team.id)

    status HTTP_STATUS_OK
    content_type :json
    @team_members.to_json
  end
end

# Get individual team members
get '/:team_id/team-members/:team_member_id.json' do
  protected!
  require_team_user!(params[:team_id])

  @team = Team.find(params[:team_id])
  if @team.present?
    team_member = TeamMember.where(:id => params[:team_member_id], :team_id => @team.id)

    status HTTP_STATUS_OK
    content_type :json
    output = team_member.to_json
  else
    outputMsg = "Invalid team"
    status HTTP_STATUS_BAD_REQUEST
    output = { :message => outputMsg }
  end

  output.to_json
end

# Add new team member
post '/:team_id/team-member/add' do
  protected!
  require_team_user!(params[:team_id])

  team = Team.find(params[:team_id])

  output = ""
  if team.present?
    request_body = JSON.parse(request.body.read.to_s)
    team_member_name = request_body["name"] if request_body.present?
  
    if team_member_name.present?
      team_member = TeamMember.create(:name => team_member_name, :team_id => team.id)
      logger.info("Added team_member: #{team_member_name}")
      status HTTP_STATUS_OK
      output = team_member

    else
      logger.warn("team_member name not present")
      status HTTP_STATUS_BAD_REQUEST
      output = { :message => "Please specify a team member name." }
    end
    
  else
    logger.warn("team not present")
    status HTTP_STATUS_BAD_REQUEST
    output = { :message => "Invalid team" }
  end

  content_type :json
  output.to_json
end

post '/team-member/:team_member_id/edit' do
  protected!
  
  team_member = TeamMember.find(params[:team_member_id])
  if team_member.present?
    new_name = params[:name]
    if new_name.present?
      team_member.name = new_name
        
      if team_member.save
        flash[:success] = "Successfully updated team member name."
      else
        flash[:warning] = "Something went wrong with saving team member name. Please try again another time."
      end
    else
      flash[:warning] = "Please specify a team member name."
    end
  else
    flash[:warning] = "Invalid team member."
  end
  
  redirect back
end

post '/team-member/:team_member_id/delete' do
  protected!
  
  team_member = TeamMember.find(params[:team_member_id])
  if team_member.present?
    name = team_member.name
    team_member.delete
    flash[:success] = "Successfully deleted '#{name}'."
  else
    flash[:warning] = "Invalid team member."
  end
  
  redirect back
end


# ----------------------------------------------------------------------------
# Error handling
# ----------------------------------------------------------------------------

not_found do
  logger.info "not_found: #{request.path_info}"
end

# All errors
error do
  send_error_email(env['sinatra.error'])
  
  erb :error
end

# Use gmail so that it does not clog up normal emails
def send_error_email(exception)
  send_to_email = "dev@pebblecode.com"
  send_from_email = settings.send_from_email
  subject = "[#{settings.environment}] Vistazo: an error occurred"
  
  email_params = {
    :address => "smtp.gmail.com",
    :domain => "vistazoapp.com",
    :port => '587',
    :enable_starttls_auto => true,
    :user_name => "vistazoapp",
    :password => "5gZ*pBirc"
  }
  
  @url = APP_CONFIG["base_url"]
  @backtrace = ""
  exception.backtrace.each { |e| @backtrace += "#{e}\n" }
  @exception = "#{exception.class}: #{exception.message}"
  
  if ENV['RACK_ENV'] == "development"
    logger.info "DEVELOPMENT MODE: email not actually sent, but this is what it'd look like..."
    logger.info "send_from_email: #{send_from_email}"
    logger.info "send_to_email: #{send_to_email}"
    logger.info "params: #{email_params}"
    logger.info "subject: #{subject}"
            
    logger.info erb(:error_email, :layout => false)
  else
    send_email(send_from_email, send_to_email, subject, erb(:error_email, :layout => false), email_params)
  end
end
