# Mongo mapper settings

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
elsif settings.environment == "test"
  setup_mongo_connection('mongomapper://localhost:27017/vistazo-test')
end

require_relative 'account'
require_relative 'team_member'
require_relative 'team_member_project'
require_relative 'project'
require_relative 'colour_setting'