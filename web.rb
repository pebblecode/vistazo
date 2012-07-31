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

set :version_string, "1.0.0 release"

# Adding this to fix IE9 bug. See #237, and http://stackoverflow.com/q/10102893/111884
set :protection, except: :session_hijacking

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
      setup_mongo(env)
    end
  end

  configure :staging do
    enable :logging
  end

  configure :development do
    setup_mongo(:development)
    set :session_secret, "wj-Sf/sdf_P49usi#sn132_sdnfij3"

    enable :logging
  end

  configure :test do
    setup_mongo(:test)
  end

  ##############################################################################

end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  # More methods in /helpers/*
end

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
# Static pages
# ----------------------------------------------------------------------------

get '/terms' do
  @is_static = true
  erb :terms
end

get '/privacy' do
  @is_static = true
  erb :privacy
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

      if @user.present?
        @user.uid = hash["uid"]
        @user.name = hash["info"]["name"]

        @user.save

        if @user.valid?
          flash[:success] = "Welcome to Vistazo! You've successfully registered."
        else
          flash[:warning] = "Could not register user."
          logger.warn @user.errors
          @user = nil
        end
      else # User not present - create one
        @user = User.create(
          :uid   => hash["uid"],
          :name  => hash["info"]["name"],
          :email => hash["info"]["email"]
        )
        if @user.valid?
          @team = Team.create_for_user(@user)

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
  if current_user?
    # logger.info "Homepage with user: #{current_user.name} with teams: #{current_user.teams}"
    redirect "/#{current_user.teams.first.url_slug}" if current_user.teams.present?
  end
  erb :homepage, :layout => false
end

# Timetable week view
get '/:team_id/:year/week/:week_num' do
  require_team_user!(params[:team_id])

  if current_user.is_new
    @first_signon = current_user.is_new
    current_user.is_new = false
    current_user.save
  end

  @team = Team.find(params[:team_id])

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
      @users = User.where(:team_ids => @team.id).sort(:name)
      @user_timetables = UserTimetable.where(:team_id => @team.id)
      @timetable_items = TimetableItem.by_team_year_week(@team, year, week_num)

      # The month from monday
      month = @monday_date.month
      @month_link_url = "/#{params[:team_id]}/#{year}/month/#{month}"

      @is_week_view = true

      erb :timetable
    else
      flash.next[:warning] = "Invalid week or year."
      redirect "/#{params[:team_id]}"
    end
  else
    flash.next[:warning] = "Invalid team."
    redirect back
  end
end

get '/:team_id/:year/month/:month' do
  require_team_user!(params[:team_id])

  @team = Team.find(params[:team_id])

  if @team.present?
    @year = params[:year].to_i
    @month = params[:month].to_i

    if ((1..NUM_MONTHS_IN_A_YEAR).include? @month) and (@year > START_YEAR)
      prev_month = ((@month - 1) <= 0) ? NUM_MONTHS_IN_A_YEAR : @month - 1
      prev_month_year = ((@month - 1) <= 0) ? @year - 1 : @year
      @prev_month_url = (prev_month_year > START_YEAR) ? "/#{params[:team_id]}/#{prev_month_year}/month/#{prev_month}" : nil

      next_month = ((@month + 1) > NUM_MONTHS_IN_A_YEAR) ? 1 : @month + 1
      next_month_year = ((@month + 1) > NUM_MONTHS_IN_A_YEAR) ? @year + 1 : @year
      @next_month_url = "/#{params[:team_id]}/#{next_month_year}/month/#{next_month}"

      @projects = Project.where(:team_id => @team.id).sort(:name)
      @users = User.where(:team_ids => @team.id).sort(:name)
      @user_timetables = UserTimetable.where(:team_id => @team.id)
      @timetable_items = TimetableItem.by_team_year_month(@team, @year, @month)

      # This month
      @month_link_url = "/#{params[:team_id]}/#{@year}/month/#{@month}"
      @days_in_month = days_in_month(@year, @month)
      @month_label = Date::MONTHNAMES[@month]
      @is_month_view = true

      erb :timetable
    else
      flash.next[:warning] = "Invalid month or year."
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

post '/teams/new' do
  if params[:new_team_name].present?
    @team = Team.create_for_user(current_user)

    @team.name = params[:new_team_name]
    if @team.save
      flash[:success] = "Successfully created team."
    else
      flash[:warning] = "Create team failed."
    end
  else
    flash[:warning] = "Create team failed. Team name empty."
  end

  # Redirect to new team
  redirect @team.present? ? "/#{@team.id}" : back
end

get '/:team_id' do
  @team = Team.find(params[:team_id])
  # logger.info "Team page (#{@team}) with user: #{current_user}"
  if @team.present?
    redirect team_id_current_week_link_url(@team.id)
  else
    flash.next[:warning] = "Invalid team."
    redirect '/'
  end
end

# Add a new user to the user timetables. If it is a new user, the
# user is added as well.
#
# Returns the user timetable and the user object in json form
post '/:team_id/user-timetables/new-user.json' do
  require_team_user!(params[:team_id])

  team = Team.find(params[:team_id])

  logger.info "New user: \nparams: #{params}}"

  output = ""
  if team
    user_name = params[:name]
    user_email = params[:email]
    is_visible = params_is_visible_value(params)

    if user_name.present? and user_email.present?
      user = User.find_by_email(user_email)

      if user.present?
        user_in_team = team.user_timetable(user)
        if user_in_team
          error_message = "#{user.name} (#{user.email}) already exists in the project."
          unless team.user_timetable(user).is_visible
            error_message += " Click on their name to make them visible in the team."
          end

          status HTTP_STATUS_BAD_REQUEST_CONFLICT
          output = { :message => (h error_message) }
        else
          team.add_user(user, is_visible)

          error_msgs = send_join_team_email_return_error_messages(current_user, user, team)
          if error_msgs.nil?
            logger.info("Added user: #{user_name} (#{user_email})")
            status HTTP_STATUS_OK
            output = { :user => user, :user_timetable => team.user_timetable(user) }
          else
            status HTTP_STATUS_INTERNAL_SERVER_ERROR
            output = error_msgs
          end
        end
      else # Create new user
        new_user = User.create(:name => user_name, :email => user_email)
        if new_user.save
          team.add_user(new_user, is_visible) # Creates new user and timetable too

          error_msgs = send_join_team_email_return_error_messages(current_user, new_user, team)
          if error_msgs.nil?
            logger.info("Added user: #{user_name} (#{user_email})")
            status HTTP_STATUS_OK
            output = { :user => new_user, :user_timetable => team.user_timetable(new_user) }
          else
            status HTTP_STATUS_INTERNAL_SERVER_ERROR
            output = error_msgs
          end
        else
          status HTTP_STATUS_BAD_REQUEST
          output = { :message => "Invalid user", :errors => new_user.errors }
        end
      end
    else
      logger.warn("Invalid input")
      status HTTP_STATUS_BAD_REQUEST
      output = { :message => "User invalid" }
    end
  else
    logger.warn("Invalid team")
    status HTTP_STATUS_BAD_REQUEST
    output = { :message => "Invalid team" }
  end

  content_type :json
  return output.to_json
end

def send_join_team_email_return_error_messages(inviter, to_user, team)
  output = nil
  begin
    send_join_team_email_with_team_link(inviter, to_user, team)
  rescue Exception => e
    logger.warn "Email error: #{e}"
    logger.warn e.backtrace.join("\n")
    output = { :message =>  "It looks like something went wrong while attempting to send your email. Please try again another time. Error: #{h e}" }
  end

  output
end

# Update team
post '/:team_id' do
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

def send_join_team_email_with_team_link(inviter, to_user, team)
  @inviter_name = inviter.name
  @to_user_name = to_user.name
  @team_name = team.name
  @team_link = "#{APP_CONFIG['base_url']}"

  logger.info("#{@inviter_name}, #{@to_user_name}")

  send_from_email = settings.send_from_email
  subject = "You are invited to Vistazo"

  send_sendgrid_email(send_from_email, to_user.email, subject, erb(:new_user_email, :layout => false))
end

# ----------------------------------------------------------------------------
# Timetable items
# ----------------------------------------------------------------------------


############################################
# Add timetable item
############################################

post '/:team_id/users/:user_id/timetable-items/new.json' do
  require_team_user!(params[:team_id])

  request_body = JSON.parse(request.body.read.to_s)
  team = Team.find(params[:team_id])
  user = User.find(params[:user_id])
  date = Date.parse(request_body["date"]) if request_body["date"]

  logger.info "Add timetable item: #{params} | #{request_body}"

  if request_body["project_id"].present?
    project = Project.find(request_body["project_id"])
    if (user.present? and project.present? and date.present?)
      timetable_item = TimetableItem.create_with_team_id_and_user_id(team.id, user.id, {
          :project => project,
          :date => date
        })

      outputMsg = "Successfully added '#{project.name}' project for #{user.name} on #{date}."

      status HTTP_STATUS_OK
      output = { :message => outputMsg, :timetable_item => timetable_item }
    else
      logger.warn "ERROR: Add existing timetable item: user: #{user}, project: #{project}, date: #{date}"
      outputMsg = "Something went wrong when adding a timetable item. Please refresh and try again later."

      status HTTP_STATUS_BAD_REQUEST
      output = { :message => outputMsg }
    end
  else # New project if there is no project id
    project_name = request_body["project_name"]

    if project_name.present?
      if team.present?
        project = Project.create(:name => project_name, :team => team)
        timetable_item = TimetableItem.create_with_team_id_and_user_id(team.id, user.id, {
          :project => project,
          :date => date
        })

        outputMsg = "Successfully added '#{project.name}' project for #{user.name} on #{date}."

        status HTTP_STATUS_OK
        output = { :message => outputMsg, :timetable_item => timetable_item, :project => project }
      else
        outputMsg = "Invalid team."

        status HTTP_STATUS_BAD_REQUEST
        output = { :message => outputMsg }
      end
    else
      outputMsg = "Please specify a project name."

      status HTTP_STATUS_BAD_REQUEST
      output = { :message => outputMsg }
    end
  end
  
  content_type :json
  output.to_json
end


############################################
# Update timetable items
############################################

post '/:team_id/timetable-items/:timetable_item_id/update.json' do
  team_id = params[:team_id]
  require_team_user!(team_id)

  output = ""
  team = Team.find(team_id)
  if team.present?
    from_user = User.find(params[:from_user_id])
    to_user = User.find(params[:to_user_id])


    timetable_item = TimetableItem.find(params[:timetable_item_id]) if from_user

    to_date = Date.parse(params[:to_date]) if params[:to_date]

    logger.info "Update timetable item params: #{params}"

    if (from_user.present? and to_user.present? and timetable_item.present? and to_date.present?)

      if ((from_user.team_ids.include? team.id) and (to_user.team_ids.include? team.id))
        timetable_item.date = to_date
        timetable_item.user_timetable = UserTimetable.find_by_user_id_and_team_id(to_user.id, team_id)
        successful_update = timetable_item.save


        if successful_update
          status HTTP_STATUS_OK
          output = { :message => "Successfully moved '#{h timetable_item.project_name}' project to #{h to_user.name} on #{h to_date}.", timetable_item: timetable_item }
        else
          status HTTP_STATUS_INTERNAL_SERVER_ERROR
          output = { :message => "Something went wrong with saving the changes when updating timetable item. Please refresh and try again later.", timetable_item: timetable_item }
        end
      else
        status HTTP_STATUS_BAD_REQUEST
        output = { :message => "Invalid team.", timetable_item: timetable_item }
      end
    else
      status HTTP_STATUS_BAD_REQUEST
      output = { :message => "Something went wrong with the input when updating timetable item. Please refresh and try again later.", timetable_item: timetable_item }
    end
  else
    status HTTP_STATUS_BAD_REQUEST
    output = { :message => "Invalid team." }
  end

  content_type :json
  output.to_json
end


############################################
# Delete timetable items
############################################

post '/:team_id/users/:user_id/timetable-items/:timetable_item_id/delete.json' do
  require_team_user!(params[:team_id])

  team = Team.find(params[:team_id])
  user = User.find(params[:user_id])
  timetable_item_id = params[:timetable_item_id]
  output = ""
  if team.present? and team.has_user_timetable? user and timetable_item_id.present?

    logger.info "Deleting: Team(#{team.id}), user (#{user.id}), timetable_item_id (#{timetable_item_id})"

    did_delete = TimetableItem.delete(timetable_item_id)

    if did_delete
      status HTTP_STATUS_OK
      output = { :message => "Successfully deleted timetable item for #{h user.name}.", :timetable_item_id => params[:timetable_id] }
    else
      status HTTP_STATUS_INTERNAL_SERVER_ERROR
      output = { :message => "Something went wrong when trying to delete a timetable item for #{ h user.name}. Please try again later.", :timetable_item_id => params[:timetable_id] }
    end
  else
    status HTTP_STATUS_BAD_REQUEST
    output = { :message => "Something went wrong when trying to delete a timetable item. Please refresh and try again later.", :timetable_item_id => params[:timetable_id] }
  end

  content_type :json
  output.to_json
end


############################################
# Delete project
############################################

post "/:team_id/project/:project_id/delete" do
  require_team_user!(params[:team_id])

  project = Project.find(params[:project_id])
  if project.present?
    if project.team_id.to_s == params[:team_id]
      logger.info "Deleting project #{project.id} and all user timetable items"
      team = Team.find(params[:team_id])
      project_name = project.name

      team.delete_project_in_timetables!(project)
      Project.delete project.id
      flash[:success] = "Successfully deleted project '#{h project_name}'."
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
# Users
# ----------------------------------------------------------------------------

# Check the value of is_visible in the passed parameters.
# True if :is_visible is present and the value is "true" (note the
# string value)
def params_is_visible_value(parameters)
  (parameters[:is_visible].present? and (parameters[:is_visible] == "true")) ? true : false
end

# Update user and user timetable
post '/:team_id/users/:user_id' do
  require_team_user!(params[:team_id])
  
  logger.info "Update user: #{params}"

  @team = Team.find(params[:team_id])
  if @team.present?
    user = User.find(params[:user_id])
    if user.present?
      new_name = params[:name]
      if new_name.present?
        is_visible = params_is_visible_value(params)
        @team.set_user_timetable_is_visible(user, is_visible)
        user.name = new_name

        if user.save
          flash[:success] = "Successfully updated user."
        else
          flash[:warning] = "Something went wrong with saving user. Please try again another time."
        end
      else
        flash[:warning] = "Please specify a user name."
      end
    else
      flash[:warning] = "Invalid user."
    end
  end

  redirect back
end

post '/:team_id/users/:user_id/delete' do
  require_team_user!(params[:team_id])

  @team = Team.find(params[:team_id])
  if @team.present?
    user = User.find(params[:user_id])
    if user.present?
      name = user.name
      @team.delete_user(user)

      user.remove_team(@team)
      unless user.has_a_team?
        User.delete user.id
      end

      flash[:success] = "Successfully deleted '#{h name}'."
    else
      flash[:warning] = "Invalid user."
    end
  else
    flash[:warning] = "Invalid team."
  end

  redirect back
end


# ----------------------------------------------------------------------------
# Error handling
# ----------------------------------------------------------------------------

not_found do
  logger.info "not_found: #{request.request_method} #{request.url}"
end

# All errors
error do
  send_error_email(env['sinatra.error'])

  @is_error = true
  erb :error
end

# Use gmail so that it does not clog up normal emails
def send_error_email(exception)
  send_to_email = "dev@pebblecode.com"
  send_from_email = settings.send_from_email
  subject = "[#{settings.environment}] Vistazo: an error occurred"

  @url = APP_CONFIG["base_url"]
  @backtrace = ""
  exception.backtrace.each { |e| @backtrace += "#{e}\n" }
  @exception = "#{exception.class}: #{exception.message}"

  send_google_email(send_from_email, send_to_email, subject, erb(:error_email, :layout => false))
end
