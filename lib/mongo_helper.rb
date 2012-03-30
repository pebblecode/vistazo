def setup_mongo(env)
	case env
	when :development
		setup_mongo_connection('mongomapper://localhost:27017/vistazo-development')
	when :test
		setup_mongo_connection('mongomapper://localhost:27017/vistazo-test')
	when :staging
		setup_mongo_connection(ENV['MONGOLAB_URI'])
	when :production
		setup_mongo_connection(ENV['MONGOLAB_URI'])
	end
end

def setup_mongo_connection(mongo_url)
  url = URI(mongo_url)
  MongoMapper.connection = Mongo::Connection.new(url.host, url.port)
  MongoMapper.database = url.path.gsub(/^\//, '')
  MongoMapper.database.authenticate(url.user, url.password) if url.user && url.password
end

def delete_all_collections
	MongoMapper.database.collections.each do |coll|
    unless coll.name.match /^system\..+/
      if defined? logger
      	logger.warn "Deleting #{coll.name}"
      else
      	puts "Deleting #{coll.name}"
      end

      coll.drop
    end
  end
end