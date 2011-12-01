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

enable :sessions



use OmniAuth::Builder do
  provider :google_oauth2, '443819582294.apps.googleusercontent.com', 'nBlfJxFwHbyOKN_PKSgTJtbt', {
  }
end


set :environment, ENV["RACK_ENV"] || "development"

require_relative 'models/init'

##############################################################################
# Helper classes
##############################################################################

def get_project_css_class(str)
  get_css_class(str, "project")
end

def get_css_class(str, prefix)
  "#{prefix}-#{str.downcase.gsub(/\W/, "-")}" if str.present?
end

class Fixnum
  def ordinalize
    if (11..13).include?(self % 100)
      "#{self}th"
    else
      case self % 10
        when 1; "#{self}st"
        when 2; "#{self}nd"
        when 3; "#{self}rd"
        else    "#{self}th"
      end
    end
  end
end

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

get '/' do
  protected!
  
  @accounts = Account.all
  
  erb :homepage
end

get '/oauth' do
  protected!
  erb :oauth
end
get '/auth/:provider/callback' do
  content_type 'text/plain'
  request.env['omniauth.auth'].to_hash.inspect rescue puts "No Data"
end

get '/auth/failure' do
  content_type 'text/plain'
  request.env['omniauth.auth'].to_hash.inspect rescue "No Data"
end

get '/:account' do
  protected!
  
  @account = Account.find_by_url_slug(params[:account])
  
  if @account.present?
    redirect "/#{params[:account]}/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
  else
    flash.next[:warning] = "Invalid account."
    redirect '/'
  end
end

get '/:account/:year/week/:week_num' do
  protected!
  
  @account = Account.find_by_url_slug(params[:account])
  
  if @account.present?
    year = params[:year].to_i
    week_num = params[:week_num].to_i
  
    if ((1..NUM_WEEKS_IN_A_YEAR).include? week_num) and (year > START_YEAR)
      # Weeks start from 1
      prev_week_num = ((week_num - 1) <= 0) ? NUM_WEEKS_IN_A_YEAR : week_num - 1
      prev_week_year = ((week_num - 1) <= 0) ? year - 1 : year
      @prev_week_url = (prev_week_year > START_YEAR) ? "/#{params[:account]}/#{prev_week_year}/week/#{prev_week_num}" : nil
    
      next_week_num = ((week_num + 1) > NUM_WEEKS_IN_A_YEAR) ? 1 : week_num + 1
      next_week_year = ((week_num + 1) > NUM_WEEKS_IN_A_YEAR) ? year + 1 : year
      @next_week_url = "/#{params[:account]}/#{next_week_year}/week/#{next_week_num}"

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
      redirect "/#{params[:account]}"
    end
  else
    flash.next[:warning] = "Invalid account."
    redirect '/'
  end
end

post '/:account/team-member-project/add' do
  protected!

  account = Account.find_by_url_slug(params[:account])
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

post '/:account/team-member/add' do
  protected!
  
  account = Account.find_by_url_slug(params[:account])
  
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

post '/reset' do
  protected!
  
  # Delete everything
  TeamMember.delete_all()
  Project.delete_all()
  ColourSetting.delete_all()
  Account.delete_all()
  
  # Seed data
  pebble_code_web_dev = Account.create(:name => "pebble{code} web-dev team", :url_slug => "pebble_code_web_dev")
  pebble_code_web_dev.update_attributes(:projects => [
    Project.create(:name => "ideapi"),
    Project.create(:name => "Space"),
    Project.create(:name => "LDN taxi"),
    Project.create(:name => "Vistazo")
  ])
  pebble_code_web_dev.update_attributes(:team_members => [
    TeamMember.create(:name => "Toby H"),
    TeamMember.create(:name => "George O"),
    TeamMember.create(:name => "Mark D"),
    TeamMember.create(:name => "Tak T"),
    TeamMember.create(:name => "Vince M"),
  ])
  
  pebble_code_dot_net = Account.create(:name => "pebble{code} .net team", :url_slug => "pebble_code_dot_net")
  pebble_code_dot_net.update_attributes(:projects => [
    Project.create(:name => "Contrarius"),
    Project.create(:name => "Bingo")
  ])
  pebble_code_dot_net.update_attributes(:team_members => [
    TeamMember.create(:name => "Toby H"),
    TeamMember.create(:name => "Alex B"),
    TeamMember.create(:name => "Greg J"),
    TeamMember.create(:name => "Matt W"),
    TeamMember.create(:name => "Daniel B")
  ])
  
  pebble_it = Account.create(:name => "pebble.it", :url_slug => "pebble_it")
  pebble_it.update_attributes(:projects => [
    Project.create(:name => "Frukt"),
    Project.create(:name => "Kane")
  ])
  pebble_it.update_attributes(:team_members => [
    TeamMember.create(:name => "Toby H"),
    TeamMember.create(:name => "Seb N"),
    TeamMember.create(:name => "Paul E"),
    TeamMember.create(:name => "David O"),
    TeamMember.create(:name => "Graham G"),
    TeamMember.create(:name => "Simon T"),
    TeamMember.create(:name => "Michael P"),
    TeamMember.create(:name => "James F"),
    TeamMember.create(:name => "Toby TAG G"),
    TeamMember.create(:name => "Gayle S")
  ])

  flash[:success] = "Successfully cleared out the database and added seed data. Enjoy!"
  redirect '/'
end

get '/css/style.css' do
  scss "sass/style".intern
end