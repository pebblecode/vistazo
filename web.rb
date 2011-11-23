require 'sinatra'
require 'sinatra/flash'
require 'mongo_mapper'
require 'uri'
require 'sass'
require 'time'
require 'date'

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
if settings.environment == "production"
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
  
  redirect "/#{Time.now.year}/week/#{Time.now.strftime("%U")}"
end


get '/:year/week/:week_num' do
  protected!
  
  year = params[:year].to_i
  week_num = params[:week_num].to_i
  
  if ((1..NUM_WEEKS_IN_A_YEAR).include? week_num) and (year > START_YEAR)
    # Weeks start from 1
    prev_week_num = ((week_num - 1) <= 0) ? NUM_WEEKS_IN_A_YEAR : week_num - 1
    prev_week_year = ((week_num - 1) <= 0) ? year - 1 : year
    @prev_week_url = (prev_week_year > START_YEAR) ? "/#{prev_week_year}/week/#{prev_week_num}" : nil
    
    next_week_num = ((week_num + 1) > NUM_WEEKS_IN_A_YEAR) ? 1 : week_num + 1
    next_week_year = ((week_num + 1) > NUM_WEEKS_IN_A_YEAR) ? year + 1 : year
    @next_week_url = "/#{next_week_year}/week/#{next_week_num}"

    @monday_date = Date.commercial(year, week_num, MONDAY)
    @tuesday_date = Date.commercial(year, week_num, TUESDAY)
    @wednesday_date = Date.commercial(year, week_num, WEDNESDAY)
    @thursday_date = Date.commercial(year, week_num, THURSDAY)
    @friday_date = Date.commercial(year, week_num, FRIDAY)
  
    @projects = Project.sort(:name)
    @team_members = TeamMember.sort(:name)

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
      flash[:warning] = "Something went wrong when adding a team member project. Please try again later."
    end
  end
  
  redirect '/'
end

post '/team-member/:team_member_id/team-member-project/:tm_project_id/update' do
  protected!

  team_member = TeamMember.find(params[:team_member_id])
  date = Date.parse(params[:date])
  
  puts "Update team member project: #{params}"
  
  project = Project.find(params[:project_id])
  if (team_member.present? and project.present? and date.present?)
    team_member.add_project_on_date(project, date)
    
    flash[:success] = "Successfully updated '<em>#{project.name}</em>' project for #{team_member.name} on #{date}."
  else
    flash[:warning] = "Something went wrong when adding a team member project. Please try again later."
  end

  
  redirect '/'
end

post '/team-member/:team_member_id/project/:tm_project_id/delete' do
  protected!
  
  team_member = TeamMember.find(params[:team_member_id])
  
  if team_member.present?
    deleted_team_member = team_member.team_member_projects.delete_if { |proj| proj.id.to_s == params[:tm_project_id] }
    team_member.save

    if deleted_team_member.present?
      flash[:success] = "Successfully deleted team member project for #{team_member.name}."
    else
      flash[:warning] = "Something went wrong when trying to delete a team member project for #{team_member.name}. Please try again later."
    end
  else
    flash[:warning] = "Something went wrong when trying to delete a team member project. Please try again later."
  end
  
  redirect '/'
end

get '/create' do
  protected!
  
  ideapi = Project.create(:name => "ideapi")
  space = Project.create(:name => "Space")
  ldn_taxi = Project.create(:name => "LDN taxi")
  vistazo = Project.create(:name => "Vistazo")
  pebblecode = Project.create(:name => "Pebble code")
  
  toby = TeamMember.create(:name => "Toby H")
  george = TeamMember.create(:name => "George O")
  mark = TeamMember.create(:name => "Mark D")
  tak = TeamMember.create(:name => "Tak T")
  vince = TeamMember.create(:name => "Vince M")

  toby.update_attributes(:team_member_projects => [
    TeamMemberProject.new(:project_id => ideapi.id, :project => ideapi, :date => Time.now),
    TeamMemberProject.new(:project_id => ldn_taxi.id, :date => Time.now),
    
    TeamMemberProject.new(:project_id => space.id, :date => Time.now + 1.day),
    
    TeamMemberProject.new(:project_id => ideapi.id, :date => Time.now + 2.day),
    TeamMemberProject.new(:project_id => space.id, :date => Time.now + 2.day),
    TeamMemberProject.new(:project_id => ldn_taxi.id, :date => Time.now + 2.day),
    
    TeamMemberProject.new(:project_id => vistazo.id, :date => Time.now + 3.day),
    
    TeamMemberProject.new(:project_id => vistazo.id, :date => Time.now + 4.day)
  ])
  
  george.update_attributes(:team_member_projects => [
    TeamMemberProject.new(:project_id => ldn_taxi.id, :date => Date.parse('2011-11-14')),
    
    TeamMemberProject.new(:project_id => ldn_taxi.id, :date => Date.parse('2011-11-15')),
    
    TeamMemberProject.new(:project_id => ldn_taxi.id, :date => Date.parse('2011-11-16')),
    
    TeamMemberProject.new(:project_id => ldn_taxi.id, :date => Date.parse('2011-11-17')),
    
    TeamMemberProject.new(:project_id => ldn_taxi.id, :date => Date.parse('2011-11-18'))
  ])
  
  mark.update_attributes(:team_member_projects => [
    TeamMemberProject.new(:project_id => vistazo.id, :date => Date.parse('2011-11-14')),
    
    TeamMemberProject.new(:project_id => vistazo.id, :date => Date.parse('2011-11-15')),
    
    TeamMemberProject.new(:project_id => vistazo.id, :date => Date.parse('2011-11-16')),
    
    TeamMemberProject.new(:project_id => space.id, :date => Date.parse('2011-11-17')),
    TeamMemberProject.new(:project_id => ideapi.id, :date => Date.parse('2011-11-17')),
    
    TeamMemberProject.new(:project_id => vistazo.id, :date => Date.parse('2011-11-18'))
  ])
  
  flash[:success] = "Successfully created new seed data. Enjoy!"
  redirect '/'
end

get '/delete_all' do
  protected!
  
  # TeamMemberProject.delete_all()
  TeamMember.delete_all()
  Project.delete_all()
  ColourSetting.delete_all()
  
  flash[:info] = "Everything is GONE, and it's all your fault! But it's ok, just create some <a href='/create'>seed data</a>."
  redirect '/'  
end

get '/css/style.css' do
  scss "sass/style".intern
end