class User
  include MongoMapper::Document

  key :name, String, :required => true
  key :uid, String, :required => true
  key :email, String, :required => true

  timestamps!

  # Relationships
  belongs_to :account

end
