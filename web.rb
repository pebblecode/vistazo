require 'sinatra'
require 'mongo_mapper'
require 'uri'
require 'sass'

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
  
  belongs_to :team_member
  belongs_to :project
end

class Project
  include MongoMapper::Document
  
  key :name, String, :required => true
  key :colour, String
  
  many :team_member_projects
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
  erb :index
end

get '/css/style.css' do
  scss "sass/style".intern
end