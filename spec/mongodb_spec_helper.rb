# Helper rspec methods for [mongodb](http://www.mongodb.org/)
module MongoDBSpecHelper
  def clean_db!
    MongoMapper.database.collections.each do |coll|
      coll.remove
    end
  end
end