class Account
  include MongoMapper::Document

  key :name, String, :required => true

  # Relationships
  many :team_members
  many :projects
  many :users

  # Validation


  def url_slug
    self.id.to_s
  end
end