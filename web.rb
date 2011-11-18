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
# Models
##############################################################################
class TeamMember
  include MongoMapper::Document

  key :name, String, :required => true
  
  many :team_member_projects
end

class TeamMemberProject
  include MongoMapper::EmbeddedDocument
  
  key :date, Date, :required => true
  
  # belongs_to :team_member
  one :project
end

class Project
  include MongoMapper::Document
  
  key :name, String, :required => true
  key :hex_colour, String
  
  # Not needed
  # many :team_member_projects
end

##############################################################################


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

get '/' do
  protected!
  
  @projects = Project.all
  @team_members = TeamMember.all
  
  erb :index
end


get '/create' do
  protected!
  
  ideapi = Project.create(:name => "ideapi", :hex_colour => "#adca3a")
  space = Project.create(:name => "Space", :hex_colour => "#e74679")
  ldn_taxi = Project.create(:name => "LDN taxi", :hex_colour => "#f7ae35")
  vistazo = Project.create(:name => "Vistazo", :hex_colour => "#a1579c")
  
  toby = TeamMember.create(:name => "Toby H", :team_member_projects => [
      TeamMemberProject.new(:project_id => ideapi.id, :date => Time.now)
    ])
  george = TeamMember.create(:name => "George O")
  mark = TeamMember.create(:name => "Mark D")
  tak = TeamMember.create(:name => "Tak T")
  vince = TeamMember.create(:name => "Vince M")

  # toby.push(:team_member_projects => TeamMemberProject.new(:project => ideapi, :date => Time.now))
  # toby.push_all(:team_member_projects => [TeamMemberProject.new(:project => ideapi, :date => Time.now)])
  # toby.push_all(:team_member_projects => [TeamMemberProject.new(:project => ideapi)])
  # tm = TeamMemberProject.new(:project_id => ideapi)
  
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