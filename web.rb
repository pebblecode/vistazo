require 'sinatra'
require 'mongo_mapper'
require 'uri'
require 'sass'
require 'time'
require 'date'

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

def get_css_class(str)
  str.downcase.gsub(/ /, "-")
end

helpers do

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
end

class TeamMemberProject
  include MongoMapper::EmbeddedDocument
  before_save :cache_project
  
  key :date, Date, :required => true
  
  # Cache project
  key :project_name, String
  key :project_hex_colour, String
  
  # Relationships
  one :project
  
  def css_class
    get_css_class(self.project_name)
  end
  
  private
  
  def cache_project
    if self.project_id.present?
      project = Project.find(self.project_id)
      self.project_name = project.name
      self.project_hex_colour = project.hex_colour
    end
  end
  
end

class Project
  include MongoMapper::Document
  
  key :name, String, :required => true
  key :hex_colour, String

end

##############################################################################


MONDAY = 1
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

    monday_of_week = Date.commercial(year, week_num, MONDAY)
  
    @projects = Project.all
    @team_members = TeamMember.all

    # Assume it's the right week of dates
    @team_member_projects_on_day = {}
    for tm in @team_members do
      @team_member_projects_on_day[tm] = {}

      (MONDAY..FRIDAY).each do |work_day|
        @team_member_projects_on_day[tm][work_day] = tm.team_member_projects.select { |proj| proj.date.wday == work_day }
      end
    end

    erb :week
  else
    redirect '/'
  end
end


get '/create' do
  protected!
  
  ideapi = Project.create(:name => "ideapi", :hex_colour => "#adca3a")
  space = Project.create(:name => "Space", :hex_colour => "#e74679")
  ldn_taxi = Project.create(:name => "LDN taxi", :hex_colour => "#f7ae35")
  vistazo = Project.create(:name => "Vistazo", :hex_colour => "#a1579c")
  
  toby = TeamMember.create(:name => "Toby H")
  george = TeamMember.create(:name => "George O")
  mark = TeamMember.create(:name => "Mark D")
  tak = TeamMember.create(:name => "Tak T")
  vince = TeamMember.create(:name => "Vince M")

  toby.update_attributes(:team_member_projects => [
    TeamMemberProject.new(:project_id => ideapi.id, :project => ideapi, :date => Date.parse('2011-11-14')),
    TeamMemberProject.new(:project_id => ldn_taxi.id, :date => Date.parse('2011-11-14')),
    
    TeamMemberProject.new(:project_id => space.id, :date => Date.parse('2011-11-15')),
    
    TeamMemberProject.new(:project_id => ideapi.id, :date => Date.parse('2011-11-16')),
    TeamMemberProject.new(:project_id => space.id, :date => Date.parse('2011-11-16')),
    TeamMemberProject.new(:project_id => ldn_taxi.id, :date => Date.parse('2011-11-16')),
    
    TeamMemberProject.new(:project_id => vistazo.id, :date => Date.parse('2011-11-17')),
    
    TeamMemberProject.new(:project_id => vistazo.id, :date => Date.parse('2011-11-18'))
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
  
  redirect '/'
end

get '/delete_all' do
  protected!
  
  # TeamMemberProject.delete_all()
  TeamMember.delete_all()
  Project.delete_all()
  
  
  redirect '/'  
end

get '/css/style.css' do
  scss "sass/style".intern
end