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