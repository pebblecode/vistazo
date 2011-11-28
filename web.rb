require 'sinatra'
require 'sinatra/flash'
require 'mongo_mapper'
require 'uri'
require 'sass'
require 'time'
require 'date'
require 'json'

enable :sessions

set :environment, ENV["RACK_ENV"] || "development"

##############################################################################
# Mongo mapper settings
##############################################################################
def setup_mongo_connection(mongo_url)
  url = URI(mongo_url)
  MongoMapper.connection = Mongo::Connection.new(url.host, url.port)
  MongoMapper.database = url.path.gsub(/^\//, '')
  MongoMapper.database.authenticate(url.user, url.password) if url.user && url.password
end
if (settings.environment == "staging") or (settings.environment == "production")
  # From heroku settings: http://devcenter.heroku.com/articles/mongolab
  setup_mongo_connection(ENV['MONGOLAB_URI'])
elsif settings.environment == "development"
  setup_mongo_connection('mongomapper://localhost:27017/vistazo-development')
end
##############################################################################


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


##############################################################################
# Models
##############################################################################
class Account
  include MongoMapper::Document
  
  key :name, String, :required => true
  key :url_slug, String, :required => true
  
  # Relationships
  many :team_members
  many :projects
  
  # Validations
  validates_uniqueness_of :name, :url_slug
  
end

class TeamMember
  include MongoMapper::Document

  key :name, String, :required => true

  # Relationships
  many :team_member_projects
  
  def add_project_on_date(project, date)
    # TODO: Check that it gets saved! Mongo doesn't check by default
    self.team_member_projects << TeamMemberProject.new(:project_id => project.id, :date => date)
    self.save
  end
  
  def move_project(team_member_project, to_team_member, to_date)
    puts "Moving from #{self.name} (#{team_member_project}) to #{to_team_member.name} on #{to_date}"
    project_id = team_member_project.project_id
    
    team_member_project.date = to_date
    self.save
    
    if self != to_team_member
      did_delete = self.team_member_projects.reject! { |proj| proj == team_member_project }
      self.save
      puts "Team member should still exist: #{team_member_project}"
      unless did_delete.nil?
        to_team_member.team_member_projects << team_member_project
        to_team_member.save
      else
        return false
      end
    end
    
    return true
  end
end

class TeamMemberProject
  include MongoMapper::EmbeddedDocument
  before_save :cache_project_name
  
  key :date, Date, :required => true
  
  # Cache project
  key :project_name, String
  
  # Relationships
  one :project
  
  def css_class
    get_project_css_class(self.project_name)
  end
  
  private
  
  def cache_project_name
    if self.project_id.present?
      project = Project.find(self.project_id)
      self.project_name = project.name
    end
  end
end

# To create a new project use
#
#      Project.create(:name => "ideapi")
#
# The class will figure out the hex colour for you. If you specify a 
# `:hex_colour` explicitly, this will still be stored, however, if the colour
# is not in `COLOURS`, the next project added will use the first colour in
# `COLOURS`
class Project
  include MongoMapper::Document
  before_save :save_hex_colour
  
  key :name, String, :required => true
  key :hex_colour, String
  
  def css_class
    get_project_css_class(self.name)
  end
  
  private
  
  def save_hex_colour
    unless self.hex_colour.present?
      # Find next colour from teh last save
      last_colour_setting = ColourSetting.first
      if last_colour_setting.present?
        last_colour_index = COLOURS.index{ |c| c.values.include? last_colour_setting.last_hex_colour_saved }
        
        self.hex_colour = last_colour_index.present? ? 
                            COLOURS[(last_colour_index + 1) % COLOURS.length].values[0] :
                            COLOURS[0].values[0]
      else
        self.hex_colour = COLOURS[0].values[0]
      end
      
      save_hex_colour_used_in_settings
    end
  end
  
  def save_hex_colour_used_in_settings
    # TODO: There must be an easier way to update! Try push/set?
    colour_setting = ColourSetting.first
    if colour_setting.present?
      colour_setting.last_hex_colour_saved = self.hex_colour
      colour_setting.save
    else
      ColourSetting.create(:last_hex_colour_saved => self.hex_colour)
    end
  end
  
end

# Colours to cycle through for projects.
COLOURS = [
    { :light_green => "#afce3f" },
    { :purple => "#ae3fce" },
    { :orange => "#eeb028" },
    { :light_blue => "#3fa9ce" },
    { :red => "#e22626" },
    { :medium_green => "#3fce68" },
    { :pink => "#f118ad" },
    { :yellow => "#fede4f" },
    { :aqua => "#1ee4bc" },
    { :dark_blue => "#5f4bd5" },
  ]
class ColourSetting
  include MongoMapper::Document
  
  key :last_hex_colour_saved, String
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

post '/team-member-project/add' do
  protected!

  team_member = TeamMember.find(params[:team_member_id])
  date = Date.parse(params[:date])
  
  puts "Add team member project: #{params}"
  
  if params[:new_project].present?
    project_name = params[:new_project_name]
    
    if project_name.present?
      project = Project.create(:name => project_name)
      team_member.add_project_on_date(project, date)
      
      flash[:success] = "Successfully added '<em>#{project.name}</em>' project for #{team_member.name} on #{date}."
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
    TeamMember.create(:name => "Satish S")
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